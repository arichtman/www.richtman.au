+++
title = "Consistency with Terraform lock files and GitLab CI"
date = 2024-05-15T13:26:58+10:00
description = "Clever caching cures consistency"
draft = true
[taxonomies]
categories = [ "Technical" ]
tags = [ "gitlab", "terraform", "iac", "cicd", "ci" ]
+++

# Consistency with Terraform lockfiles and GitLab CI

## Problem

- Terraform uses the concept of a lock file to map between the semver provider constraints specified, the resolved provider semver, and the binary hashes.
- Binaries are stored in the Terraform cache, usually `./.terraform`.
- Terraform lock files and the Terraform cache are checked and populated only on the `init` command.
- Terraform `apply` fails if the cache does not match the lock file, and does not repopulate the Terraform cache.
- Terraform `plan` and `apply` operations should be separate CICD actions, with `apply`'s behaviour dictated by the output of `plan`.

[Just take me to the fix!](#solution)

## Analysis

We want the lock file for reproducability, especially cross-platform, over time, and between local runs and in CICD.

Our options are either:

- Keep the lock file.
  Add the binaries to the existing `plan` Artifact.
  This wastes storage of the binaries, but will ensure consistency in all runs.
- Keep the lock file.
  Re-run the `init` command in the `apply` job.
  This wastes network and time as it re-downloads the binaries according to the lock file.
- Remove the lock file.
  *Either* add the binaries to the Artifact *or* re-run `init` in the `apply` job.
  This removes reproducability _and_ costs us time/network/storage.
  We can rule this out immediately.

If we use Artifacts, we must store the binaries again and again for each pipeline.
GitLab's `cache` feature is less persistent and reliable than Artifacts, however, it does span pipelines (optionally).
The lock file is a point-in-time deterministic map from semver constraints specified, to the resolved semver + platform binary hashes.
GitLab allows setting the cache key based on specific files.

## Solution

Since the cache contents is entirely determined by the lock file, we'll configure the cache key based on the lock file.
This way if the lock file changes, the cache is invalidated and rebuilt.

On reducing errors:

If the cache is populated, `init` is almost a no-op.
This still costs us a bit of time as it locks the state (though it can be disabled with `-lock false`).
If we leave `init` in the `apply` job, it should reduce the amount of erroneous errors where the cache hasn't restored properly.

Below is a minimal implementation.

```yaml
.terraform__common:
  cache:
    paths:
      - .terraform
    key:
      files:
        - .terraform.lock.hcl

plan_terraform:
  stage: build
  extends:
  - .terraform__common
  script:
  - terraform init
  - terraform plan -out tfplan
  artifacts:
    paths:
    - tfplan

apply_terraform:
  stage: deploy
  extends:
  - .terraform__common
  script:
  - terraform apply tfplan
```

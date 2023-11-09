+++
title = "CI/CD with Terraform and Private Git Modules"
date = "2023-10-18T10:17:40+10:00"
description = "Wiggly, but simple enough."
draft = false
[taxonomies]
categories = [ "Technical" ]
tags = [ "git", "gitlab", "iac", "terraform", "terragrunt", "cicd" ]
+++

## Problem

We're using Terraform modules by way of [generic git repository](https://developer.hashicorp.com/terraform/language/modules/sources#generic-git-repository).
In CI/CD it's failing to pull the module due to lack of permissions.
We need a way that A) doesn't fix any credentials in the code base, and B) works both locally for developers and in automation

[Just take me to the fix!](#solution)

## Analysis

We're doing this in the context of GitLab, but the limitations apply to any similar platform.

Terraform wisely offloads auth to `git` here, and offers no `module` HCL options for usernames or passwords.
Thus, we'll explore our Git authentication options.

Git works well over SSH, let's see what our options are there.
GitLab-wise we'll need to be able to create an SSH key that has the right permissions.
This is possible via _deploy keys_.
Next, we'll need some way to get git to use this.

However, we have no control over the path that the secret is mounted to.
So we can't drop it in `~/.ssh` or anywhere that's used by default.
This will mean we have to configure git to use the key by path.

We _could_ use `GIT_SSH_COMMAND`, and point the `--identity` flag at our key.
This works, but is definitely a bit wonky.
If that escape hatch is ever required for other reasons, they'll have to somehow know to add the flags cumulatively.

We could also do a little two-step, set the config file, and in the config file set the credentials file path.
However, if we set any of `GIT_CONFIG` or the `GIT_CONFIG_*` variants, it impacts the GitLab runner's behaviour too!
Yes, both in GitLab CI variables **and** in the job's `variables:` section.
Why's that? Well the environment variable must be getting set _before_ the container is launched.
I'm sure there's a non-trivial reason it's done this way.
In fact, it's likely how setting `DOCKER_AUTH_CONFIG` works for authenticating to private image registries for runner image pulls.
So this option is out.

We could explicitly set `GIT_CONFIG*` in the job's script.
This still feels a little janky.
I'm also not sure how environment variables play out if used _in_ a git config file.
We could do an `envsubst` call on the config file but now we're just in bodgeville.

## Solution

Git has two features we can combine for this.
One is the URL rewrite `insteadOf`, the second is the `GIT_CONFIG_*` options.
This snippet speaks for itself.
<!-- Don't worry about the token, it's never been valid -->

```bash
# Setup, in CI at least the password should be protected
export USERNAME="arichtman-srt"
export PASSWORD="glpat-l9gy9ZIp2ciyx1wZJn7k"
export FQDN=gitlab.com

# This is optional, for local testing it's handy as it removes any of the actual machine's config from the equation
export GIT_CONFIG_GLOBAL=/dev/null

GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0=url.https://${USERNAME}:${PASSWORD}@${FQDN}.insteadOf \
GIT_CONFIG_VALUE_0="https://${FQDN}" \
git clone https://gitlab.com/arichtman-srt/oidc-test.git
```

It's recommended to use a token not bound to a human user for this.
In GitLab this means not using a _PAT_ but rather a _deploy token_.

## References

- [Hashicorp TF module source docs](https://developer.hashicorp.com/terraform/language/modules/sources#generic-git-repository)
- [Stack overflow answer about config env vars](https://stackoverflow.com/a/68697328)
- [Git documentation](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables)

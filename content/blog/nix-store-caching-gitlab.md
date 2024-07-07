+++
title = "Nix Store Caching in GitLab CI"
date = 2024-07-05T12:30:12+10:00
description = "Save, save save!"
draft = true
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "nixpkgs", "gitlab", "cicd" ]
+++

<!-- Revoked until I sort out the symlinking issue -->

## Problem

CI nix builds are slow.

## Solution

Modify the store location to somewhere in-scope for the cache.
Cache said location.

[Sample repo](https://gitlab.com/arichtman-srt/gitlab-ci-nix-caching)

```YAML
run_with_cache:
  stage: build
  image:
    name: docker.io/nixpkgs/nix-flakes:nixos-24.05
  script:
    - nix build --store "$CI_PROJECT_DIR/nix-store" .#yoohoo
  cache:
    paths:
    - 'nix-store/**/*'
    unprotect: true
    when: always
    key:
      prefix: nix-store
      files:
      - flake.lock
```

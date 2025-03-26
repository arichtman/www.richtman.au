+++
title = "Platform Engineering Journey - Part 3"
date = 2025-03-26T21:06:58+10:00
description = "Nuts and Bolts (maybe)"
draft = true
[taxonomies]
categories = [ "Meta" ]
tags = [ "platform-engineering", "platform-engineering-journey" ]
+++

# ??

- Clear we needed to change something technically
- Had ArgoCD, EKS, Infrastructure Monorepo, Atlantis
  - All the buzzwords and it sucked!
  - Atlantis workflow cumbersome
  - Never-solved issue of apply-then-merge vs merge-then-apply
  - Difficult to use the monorepo locally
  - Blowouts in CI jobs and running times as the DAG grew
  - Despite separating state well, coupling outputs caused blast radius to span basically every account
  - Extremely painful to change any APIs
  - TF modules spread out across a mix of verioned and unversioned modules in git repos
    (had opted NOT to use registries cause who needs more auth issues)
  - Personal distaste for HCL
  - Semantics encoded in file hierarchy leading to deep nesting to achieve granularity
    (this is RECOMMENDED)
  - Terragrunt behaviour is opaque, unclear what it's procedure is
  - Terragrunt does too much, unclear which features should be used together and which not
  - Monorepo dangerous so had to limit who can apply, which bottlenecks and turns Platform into gatekeepers
  - Monorepo unintelligible without sufficient experience.
    MAjor difficulty for developers who visit it once a week _maybe_.
  - Anything coupled between TF and application e.g. database URL no good way to link
    (but you get this anywhere you put terraform, you can only move the coupling)
- Had a simplified, vanilla Terraform pattern for applications
  - But this didn't compose well for anything that crossed applications
- Living a double life of Terraform and Kubernetes was burning us out
  - No good boundary between the two
  - Fundamentally different philosophies about state management and applying changes
  - Terraform to manage Helm charts not working
  - Issues with EKS Add-ons, TF them, Helm chart them? ArgoCD them?
- Had done some exploratory work on Crossplane
- ACK and KRO pretty freshly released
- Now was the time

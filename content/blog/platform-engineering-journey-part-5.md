+++
title = "Platform Engineering Journey - Part 5"
date = 2025-03-26T21:23:51+10:00
description = "Cold Reality"
draft = true
[taxonomies]
categories = [ "Meta" ]
tags = [ "platform-engineering", "platform-engineering-journey" ]
+++

Note: you may wish to read these in order or at least the [organizational context](./platform-engineering-journey-part-0.md)

Note: The opinions in this article are just that, my opinions.
They were made with my experience, organizational context and needs in mind.

# Back to Earth

- Nickel
  - New - how battle-tested is it?
  - Tweag/Rust - good pedigree
  - Super niche - community support? Tweag does Nix hour...
  - Schema definitions
  - Excellent errors
  - No boilerplate solution
- KDL
  - Disliked syntax
  - Seems to hold XML as an inspiration
  - Less documentation
- KRO
  - Brand new
  - Backed by all 3 major cloud providers
  - Literally says "do not use in prod"
  - Literally 5 pages of documentation
  - Combinatoric explosion due to lack of composition
  - Does add DAG/serial application to Kubernetes
    But is this a good thing? Or a big violation of principals that's going to bite hard?
- Jsonnet
  - Ugly as sin
  - Very mature
  - JSON-focussed (duh) which both works and doesn't
  - First-class functions
  - Schema definition
- Tanka
  - Builds on Jsonnet
  - Used & maintained by Grafana - good pedigree
  -
- Crossplane XRDs
  - We probably need Crossplane anyway, TF provider breadth of coverage is too good
  - Crossplane also supports arbitrary Terraform, so we can lift-n-shift some stuff
  - v2.0 coming out with some improvements like namespaced CRDs
  - Changes to licensing means only `latest`, which is a worry for critical infra
  - Extremely opaque - difficult to debug and reason about
  - Very verbose syntax
  - Just far too much YAML and rube-goldberging
  - Can't run locally
  - Arbitrary container runs - security but also guiding rails
    I'm happy they didn't continue to extend XRDs though.
- Nix
  - Too niche - not enough community support and others won't know it
  - Not enough bootstrapping/boilerplate generation, even kubernix
  - Seems basically unused or little maintained
  - Pro: might get the org using more Nix or would be a bonus if we used Nix more
- CueLang
  - Very GoLangy - noone here has experience with GoLang
  -
- Timoni
  - Stefan Prodan - good pedigree
  - Flux/ArgoCD integration (CHECK!!)
- Helm
  - SUPER common - lots of community support and existing art
  - Composes extremely poorly
  - No concept of data structures
  - ArgoCD obviates any of the lifecycle features
  - GoTmpl not great
  - Complex logic or control flows difficult
  - Testing story not great
- ytt
  - Did not review
- Open Application Model
  - Standard but not bespoke, and we have a LOT of apps that use AWS services
    Going this route would discard a lot of benefits of cloud managed services
  - Tied to KubeVela
  - Opinionated on deployment/lifecycle "workflows"
- Kusion
  - Looks like it wants to be the whole story
- Dhall-Kubernetes
  - Unmaintained
  - Could pick it up but noone here knows or wants Dhall particularly
  - Both Dhall and Dhall-Kubernetes don't seem to have had as much baking
- CubeCtl
  - Also CueLang
  - Unmaintained and exploratory

## But, soft! what light through yonder window breaks?

KAY-SEE-EHL

## References

- [Exploratory work on alternative manifest systems spanning AWS and Kubernetes](https://gitlab.com/arichtman-srt/platform-demo/).
  This was the source for most of this post, though some more recent reviews have happened.

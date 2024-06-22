+++
title = "Kubernetes the Nix Way - Part 0"
date = 2024-06-22T17:57:27+10:00
description = "In which our ~foolish~ brave protagonist embarks upon a quest."
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "nixos", "kubernetes", "k8s", "k8s-nix-way" ]
+++

## Kubernetes the Nix Way - Part 0

Some of you may know I've been wrangling vanilla Kubernetes on a combination of bare metal and VMs at home for a while.
I've been using NixOS for the host operating system, and using the NixPkgs `services.kubernetes` module.

While I've been able to work around/with the provided module, it's been difficult at times.
While trying to get Cilium CNI deployed I found an opinionated configuration of the `containerd` CRI.
This had no extension points or configurability, once again halting me in my tracks.

I've decided thus, to author my own module for Kubernetes.
In similar vein to Kelsey Hightower's _Kubernetes the Hard Way_, I'll take this as a learning and writing opportunity.

Welcome, to _Kubernetes the Nix way_.

## References

- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

+++
title = "Kubernetes the Nix Way - Part 1"
date = 2024-06-22T18:09:15+10:00
description = ""
draft = true
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "nixos", "kubernetes", "k8s", "k8s-nix-way" ]
+++

## Kubernetes the Nix Way - Part 1

We'll keep using SnowfallOrg's `lib`, I find it convenient for wiring stuff up.
Be warned though, the convenience stopped me from learning quite a few foundationals of Nix.

Our first step is going to be getting `etcd` up and running.
For now I'm going to set each component into it's own `nix` file.
Hopefully that stays nice and encapsulated, though cross-references might be spaghetti.

I'll also add a general library `nix` file.

Ideally I'd like certificate generation to be Nixified.
I have seen an `mkCert` function about, not sure how deterministic it can be when time is essential.

## References

- [State of work](https://github.com/arichtman/nix/commit/a1db3c777f10f4a462b3a4963ec325482e6ddf3a)

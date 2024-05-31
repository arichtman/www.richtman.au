+++
title = "Building OCI Container Images with Nix and Flakes"
date = 2024-05-31T13:11:41+10:00
description = ""
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "oci", "containers", "nix-flakes" ]
+++

# Problem

We have a devShell we're happy with.
CI jobs take time and bandwidth if we start with a vanilla NixOS container.
We could cache the Nix store in CI but then invalidation becomes tricky.
Let's use the devShell to build a container image for use in CI.

## Analysis

There are several options for building OCI images using Nix.
This post will look at two from NixPkgs, and one from a community project.

First up is `dockerTools.builtImage`.
This is one of the simplest ways to build an image, as it only requires two, relatively simple inputs!

```nix
{
  description = "Simple nixpkgs container image";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6132b0f6e344ce2fe34fc051b72fb46e34f668e0";
  };
  outputs = {nixpkgs, self, ... }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
  };
in
{
  packages = {
    build-image = pkgs.dockerTools.buildImage {
      name = "nix-image";
      copyToRoot = [ pkgs.hello ];
    };
  };
}
```

That's it!
We can realise the package/derivation and produce an OCI-compliant tarball with `nix build .#packages.build-image`.
Let's check our container `podman image load --input ./result` or something like `docker image load < result`

There are a few more options though that you're likely to want.
Here we have a base `FROM` image specified, as well as an `ENTRYPOINT` and `WORKDIR`.
Finding the sha256 for things is a bit of a pin, so consider using placeholder `pkgs.lib.fakeSha256` temporarily.
I located the `imageDigest` with `skopeo inspect docker://alpine:latest | jq " .Digest "`.

More configuration is available, check the NixPkgs manual's `dockerTools` link in [References](#references).
There's also `dockerTools.buildLayeredImage`, which will be much noisier on inspection but breaks out the layers to more effectively cache builds.

```nix
{
  description = "Simple-ish nixpkgs container image";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6132b0f6e344ce2fe34fc051b72fb46e34f668e0";
  };
  outputs = {nixpkgs, self, ... }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
  };
in
rec {
    alpine = pkgs.dockerTools.pullImage {
      imageName = "alpine";
      imageDigest = "sha256:77726ef6b57ddf65bb551896826ec38bc3e53f75cdde31354fbffb4f25238ebd";
      sha256 = "LYJt8aoabDtkB7s0juYohLNR4HBYtCUVeb+DupwWbEA=";
    };
  packages = {
    build-image = pkgs.dockerTools.buildImage {
      name = "nix-image";
      tag = "not-latest";
      fromImage = alpine;
      copyToRoot = [ pkgs.hello ];
      config = {
        Entrypoint = [ "${pkgs.hello}/bin/hello" ];
        WorkingDir = "/work-dir";
      };
    };
  };
};
}
```

Next we'll look at unifying our `devShells` and our container images.
To do this, we'll swap to `dockerTools.streamNixShellImage`.
This is a wrapper function, that wires up building a streaming container image out of a Nix shell.
It takes less "docker-ey" inputs, as in it'll reject stuff like `fromImage` entirely, and expects a full derivation.
Luckily, we can just feed it our shell.

This one has a slightly different output, `result` is actually, wait for it...
A shell script wrapper to an `exec` call to a Python script that reads a JSON config file, constructs an image from it,
then constructs an OCI tar and prints it to `stdout`. Whew.
Luckily, the short of it is `./result | podman load`.

The big benefit of this is you get really the same `stdenv` as your `devShell` would have built.
Pretty neat!
One downside, however, is that the images seem much larger than when we *just* fed in packages.

```nix
{
  description = "A more daring, streaming container image";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6132b0f6e344ce2fe34fc051b72fb46e34f668e0";
  };
  outputs = {nixpkgs, self, ... }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
  };
in
rec {
  packages = {
    stream-image = pkgs.dockerTools.streamNixShellImage {
      name = "nix-image";
      tag = "oldest";
      drv = devShell;
    };
  };
    devShell = pkgs.mkShell {
      buildInputs = [ pkgs.hello ];
  };
};
}
```

We're going to try out the popular community project [nix2Container](https://github.com/nlewo/nix2container).
This library gives us some different ergonomics and controls.

One immediate difference, is that to "build" these, we actually `nix run` some wrapper scripts around `skopeo`.
For example; `nix run .#packages.n2c-image.copyToDockerDaemon` or `nix run .#packages.n2c-image.copyToPodman`.
This makes it slightly more costly to build, as you have to compile Skopeo I think.
It also is opinionated, so if you wanted just a tarball you could unzip and poke around, it makes more work for you.

It _does_ take our `devShell` straight into `copyToRoot`, but it doesn't seem to symlink anything to `/bin`, nor modify `$PATH`.

```nix
{
  description = "A third-party-build container image";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6132b0f6e344ce2fe34fc051b72fb46e34f668e0";
    nix2container = {
      url = "github:nlewo/nix2container/20aad300c925639d5d6cbe30013c8357ce9f2a2e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {nixpkgs, nix2container, self, ... }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
  };
in
rec {
  packages = {
    n2c-image = nix2container.packages.${pkgs.system}.nix2container.buildImage {
      name = "nix-image";
      tag = "n2c";
      copyToRoot = devShell;
      config = {
        Cmd = ["${pkgs.hello}/bin/hello"];
      };
    };
  };
    devShell = pkgs.mkShell {
      buildInputs = [ pkgs.hello ];
  };
};
}
```

## Article Notes

- This article focuses on flakes and uses explicit single-system ones.
  The flake focus is because that's what I use, the single-system decision is to keep the Nix focussed and easily grokable.
- The flake should really also put the packages under `x86_64-linux` for the flake schema, but we're keeping it simple.
- All these will work in arbitrary Nix files and with things like Flake Utils `forEachSystem`.
  These, however, are left as a reader exercise.
- We use `rec` in some places here to colocate stuff.
  However it's generally better avoided by use of the `let` block.
- I have pinned the commits precisely on inputs to ensure this stays reproducable.
  The original article was worked using `nixpkgs-unstable` branch though.
- The system type is hardcoded to `x86_64-linux`.
  I have not tested this on other systems bar `aarch64-darwin` and yes, they build but with the wrong binaries.
  There almost certainly is a way to cross-compile, toot at me, send a PR, or email me or something if you know how.
- I've left most references to `pkgs` explicit and fully qualified, so readers know where things are coming from.
  This repetition could definitely be reduced.

## References

- [Help from Ruther/@rutherther in unofficial Nix/OS discord]
(https://discord.com/channels/568306982717751326/1247029463078932520)
- [NixPkgs manual on `dockerTools`](https://ryantm.github.io/nixpkgs/builders/images/dockertools/)

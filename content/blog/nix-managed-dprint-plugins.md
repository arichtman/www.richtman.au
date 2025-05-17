+++
title = "Nix-managed Dprint Plugins"
date = 2025-05-18T09:01:37+10:00
description = ""
[taxonomies]
categories = [ "Technical" ]
tags = [ "dprint", "nix", "nixpkgs" ]
+++

I saw a suggestion in Nixpkgs for _how_ to do this, but didn't find anyone using it.
So, presented here for others.

## Problem

Dprint can manage it's own plugins.
However this conflicts with a Nix-managed Dprint configuration.
You can manually manage the versions (and have them outside of the Nix store).
Alternatively you can just, not manage Dprint configuration in Nix.

## Solution

Dprint allows not only names, but HTTP URLs and file paths as plugin sources.
So we can create `dprint.nix`:

```nix
{pkgs, ...}: {
  # ... Other config here
  plugins = with pkgs; dprint-plugins.getPluginList (
    plugins: with dprint-plugins; [
      dprint-plugin-toml
      # ... Other plugins here
    ]
  );
}
```

...and wire that into Home-Manager:

```nix
{
  file.".dprint.jsonc".text = builtins.toJSON (import ./dprint.nix {inherit pkgs;});
}
```

## References

- [Dprint configuration docs](https://dprint.dev/config/)
- [Nixpkgs Dprint suggestion](https://github.com/NixOS/nixpkgs/blob/e06158e58f3adee28b139e9c2bcfcc41f8625b46/pkgs/by-name/dp/dprint/plugins/default.nix#L73)

+++
title = "Kubernetes the Nix Way - Part 2"
date = 2024-07-20T13:05:23+10:00
description = "Depeche Module, Modulus Operandi, Modulicule"
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "nixos", "kubernetes", "k8s", "k8s-nix-way" ]
+++

## Kubernetes the Nix Way - Part 2

Next we're going to continue wiring up our controller.
What we essentially want to do is set up a DAG of configuration that just all falls into place once the few first dominos have been pushed.
In order to achieve this we'll want something like `controller.enabled` to set up `etcd`.
Luckily there's already a NixOS module for `etcd` in NixPkgs - so some work is saved there.

When consuming modules, you can just plop your configuration top-level, no need to nest.
For example `environment.systemPackages = [ pkgs.hello ];`.
However, when authoring a module, we're now introducing `options`, which we have to distinguish from `config`.

_Options_ are the interface, essentially the schema of what you can set, with what expected types, defaults, descriptions, and more.
You can check out the full specification in the reference links.
_Config_ is the actual concrete values set for the options.
It's the realised outcome of the whole function being evaluated (still lazily!).
So, when we're having both of these in the same scope, we need to distinguish them.
Which looks like this:

```nix
options.services.k8s = {
  controller = lib.options.mkOption {
    description = ''
      Whether this is a controller
    '';
    default = false;
    type = lib.types.bool;
  };
};
config.services.k8s.controller = true;
```

We're quickly escalating how much is in `default.nix`, but we're also confusing responsibilities.
Let's see about pulling our `etcd` stuff out into it's own using imports.
There are 2.5 ways to do imports that I know of at this time.

The first, is an explicit import and assignment, this allows us to reference any attributes set in the library file.
The attributes may be any type, including functions and nested attribute sets.

`my-library-file.nix`

```nix
{
  my-library-value = "shamwow";
}
```

`default.nix`:

```nix
{...}:
{
  my-library = import ./my-library-file.nix;
  config.environment.variables.arbitrary-name = my-library.my-library-value;
}
```

The second is the module `imports` attribute, by setting this, the file will be picked up and evaluated.
This allows composition of configuration.
Here's an example that will result in both `main-value` and `sub-value` being set.
Note the lack of any direct reference to or call of `my-submodule.nix`'s properties.

`my-submodule.nix`

```nix
{...}:
{
  config.environment.variables.sub-value  = "3";
}
```

`default.nix`:

```nix
{...}:
{
  imports = [ ./my-sub-module.nix ];
  config.environment.variables.main-value = "5";
}
```

The final 0.5 of imports is by directory, e.g. `imports = [./my-dir ];`, where `my-dir/default.nix` is another module definition.
This also works for explicit assigment but assumes it's a module and executes it e.g. `myThing = import ./my-dir`.

`my-dir/default.nix`

```nix
{...}:
{
  config.environment.variables.bar = "shamwow";
}
```

## References

- [State of work](https://github.com/arichtman/nix/tree/a7a2d7178834024ff2554873a7740593e94fecbf)
- [Wakapi module](https://github.com/isabelroses/beapkgs/blob/main/modules/nixos/wakapi.nix)
- [Network block device module blog](https://scvalex.net/posts/58/)
- [Nixpkgs manual on mkOption](https://ryantm.github.io/nixpkgs/functions/library/options/)

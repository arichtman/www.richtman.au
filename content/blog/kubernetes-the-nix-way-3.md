+++
title = "Kubernetes the Nix Way - Part 3"
date = 2024-07-28T17:52:19+10:00
description = "Wrangling strings, systemd, and the development REPL"
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "nixos", "kubernetes", "k8s", "k8s-nix-way" ]
+++

## Kubernetes the Nix Way - Part 3

Continuing on with the controller, it's time to get the brains of the operation up - the API server.
This portion will mostly be about A) wrangling `systemd` by way of Nix, and B) doing our first cross-config wiring.
As is the theme, we'll be removing most of the dials and options that aren't immediately necessary.

The Kubelet is deprecating CLI arguments in favor of a configuration file.
However, it does not seem the same is happening for the API server.
Thanks to [KubeFred](https://techhub.social/@kubefred) for helping confirm that.

That in mind, the method of the existing module makes a little more sense.
It's still ugly as sin though.

```text
...
--bind-address=${cfg.bindAddress} \
${optionalString (cfg.advertiseAddress != null)
  "--advertise-address=${cfg.advertiseAddress}"} \
${optionalString (cfg.clientCaFile != null)
  "--client-ca-file=${cfg.clientCaFile}"} \
--disable-admission-plugins=${concatStringsSep "," cfg.disableAdmissionPlugins} \
--enable-admission-plugins=${concatStringsSep "," cfg.enableAdmissionPlugins} \
...
```

I think I'll try to make it a bit more data-oriented, rather than one long string interpolation.
But what to use? Normally I use `concatStringsSep`, but `intersperse` looks just as suitable.
`intersperse` will require an additonal `concatStrings` call, as it returns a list.
`intersperse` has an actual implementation in `lib`, whereas `concatStringsSep` is just an exposure of the builtin.
Actually - let's get really clever.
These are almost all argument-value pairs, let's use a mapping function to append `=` if it's a flag and a space if it's a value.

We will make our check dumbly compare the first two characters of the string, and condition on that.
I can already tell this is going to cause issues with complex value sets, and optional arguments, but we'll contend with that as we need.

```nix
{
  serviceArgs = lib.concatMapStrings
    (x: if (builtins.substring 0 2 x) == "--" then "${x}=" else "${x} ")
    [
      "--allow-privileged"
      "true"
    ];
  test = lib.asserts.assertMsg (serviceArgs == "--allow-privileged=true ") "serviceArgs malformed";
}
```

Deploying this to the machine every time we wish to test is pretty slow.
Nix REPL is kindof a limited environment to work in, I'd rather have my text editor.
There are a couple of options here.

One is we write our stuff as normal, send it to the system clipboard buffer, then enter the Nix REPL and just paste in.
This kindof works, you'll need to remember to `:lf <nixpkgs>` or `:lf github:nixos/nixpkgs` each time before pasting though.
It also only lets you test the "leafs" of your config effectively, as any complex stuff isn't automatically in context.

Another option is to build the Nix machine config locally and inspect that.
You will need to adjust the attribute path to point to your Nix machine configuration.
`nix build .#nixosConfigurations.fat-controller.config.system.build.toplevel`
I chose to dump the `ExecStart` generated string to an arbitrary file in `/etc`,
but it's similarly trivial to inspect `result/etc/systemd/system/k8s-apiserver.service`.

We work our way down the CLI reference for `kube-apiserver`, putting in place our certificates and settings.
When unsure I referenced the existing module for some of the defaults.
I'm quite surprised my extremely rudimentary argument construction got all the way to working.
I had some interesting troubles, the Kubernetes user and group had changed, so it couldn't access it's certificates.
We also had to open 6443 on the firewall.
I switched to `nftables` firewall to limit access from IP CIDRs under my control.
We shall see what this does to `containerd` later.
I also had to manually delete a `service` representing the cluster IP in `default` namespace as it was IPv4 and no longer worked with single stack IPv6.
It was automatically recreated.
After playing whack-a-mole with errors I eventually got the API server running atop `etcd`.

See the _State of work_ link for exactly what the setup looks like.

## References

- [State of work](https://github.com/arichtman/nix/tree/02050d1c9def3789034b4446a57eb7e92dcf63a9/modules/nixos/k8s)
- [Kubernetes API server cli reference](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
- [NixOS existing module](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/cluster/kubernetes/apiserver.nix)
- [Blog on using Nix REPL](https://aldoborrero.com/posts/2022/12/02/learn-how-to-use-the-nix-repl-effectively/)
- [NixOS wiki on conditionals](https://nixos.wiki/wiki/Nix_by_example#Conditionals)
- [Nix cookbook on Systemd and if-then-else](https://ops.functionalalgebra.com/)

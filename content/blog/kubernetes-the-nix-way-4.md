+++
title = "Kubernetes the Nix Way - Part 4"
date = 2024-08-21T18:05:30+10:00
description = ""
draft = true
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "nixos", "kubernetes", "k8s", "k8s-nix-way" ]
+++

## Kubernetes the Nix Way - Part 4

When we left off last time, the kubelet service was in and starting up, but failing to authorize to do anything with the API server.
Turns out this is due to the _Authorization Mode_ being left as only RBAC.
Set it to `RBAC,Node` and badda-bing badda-boom.

Kubelet was missing `iptables` binary.
Systemd service options includes `path` option to set packages.

Now, we forgot to set the pod CIDR in our kubelet config.
This isn't terrible but we want to eventually manage this dynamically,
and even though the control node is tainted noschedule and noexecute, we should make inroads on this.
The latest kubelet is now supporting a config drop-in directory **in addition to** the `--config` argument, how lucky is *that*?
So let's specify that directory and create one.
We need it writable from outside NixOS configuration, so we'll use the same mechanism as `etcd` does, `systemd` _tmpfiles_!

This one was a little tricky, since NixOS options just says `systemd.tmpfiles.settings.<name>.<name>.<name>`.
The first `<name>` is the title of the file that will be provided to configure Systemd's tmpfiles.
It'll be suffixed with `.conf`, stored in the Nix store, and symlinked into `/etc/tmpfiles.d/`.
The second is the location of the file or directory, the _target_, if you will.
For our use case I've selected the existing working directory of the kubelet, and set an additional path.
The final name is the `tmpfiles` _Type_, you can read about this in the linked reference.
Here we've used `d` type for persistent directory, though we may change to a more ephemeral type later.

```nix
tmpfiles.settings."kubelet-config-dropin"."/var/lib/kubelet/config.d" = {
  d = {
    user = "kubernetes";
    mode = "0755";
  };
};
```

## References

<!-- - [State of Work]() -->

- [Systemd tmpfiles](https://www.freedesktop.org/software/systemd/man/tmpfiles.d)

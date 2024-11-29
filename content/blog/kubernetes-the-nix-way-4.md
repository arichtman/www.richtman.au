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

Note: Around this time ICANN approved the `.internal` TLD and I switched my home network over to that.
This will explain the shift from `.local`.

When we left off last time, the kubelet service was in and starting up, but failing to authorize to do anything with the API server.
Turns out this is due to the _Authorization Mode_ being left as only RBAC.
Set it to `RBAC,Node` and badda-bing badda-boom.

```
serviceArgs =
  [...]
  "--authorization-mode"
  "RBAC,Node"
```

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

Having that all up and running, I attempted to run some pods.
This yielded errors from the kubelet stating that it had failed to execute `mount`, having not found it on `PATH`.
This seems odd since `mount` is accessible to both `nixos` and `root` users.
Systemd service options includes `path` option to set packages.
The solution is to add the `mount` package explicitly to the NixOS service configuration.
This ensures it will be on `PATH` and available to the service when running.

```
systemd = {
  services.k8s-kubelet = {
    [...]
    path = with pkgs; [
      mount
    ];
  };
```

In trying to debug the pod initialization errors, I ran `kubectl logs`, only for it not to work.
The error complained about not resolving the host name.
Inspecting the `node` resource yielded some clues.

```yaml
apiVersion: v1
kind: Node
metadata:
  name: patient-zero
  labels:
    kubernetes.io/hostname: patient-zero
status:
  addresses:
  - address: patient-zero
    type: Hostname
[...]
```

The node name being unqualified feels correct, I suspect this is more an issue with GoLang using its own DNS resolution path,
which presumably is skipping mDNS.
We verify this by running with some debug flags.

```
$ GODEBUG=netdns=9 kubectl get no

go package net: confVal.netCgo = false  netGo = false
go package net: cgo resolver not supported; using Go's DNS resolver
go package net: hostLookupOrder(fat-controller.local) = files,dns
[...] Usual output
```

Still, for now we can hack around this.

```
serviceArgs =
  [...]
  "--hostname-override"
  "${config.networking.hostName}.local"
```

This yields the fully qualified mDNS domain, but GoLang is still not using mDNS for resolution,
so this solves nothing.

## References

- [State of Work](https://github.com/arichtman/nix/commit/ae11adcfe8fbca335d5451389bcb3bf470c44741)
- [Systemd tmpfiles](https://www.freedesktop.org/software/systemd/man/tmpfiles.d)
- [GoLang DNS lookup post](https://jameshfisher.com/2017/08/03/golang-dns-lookup/)

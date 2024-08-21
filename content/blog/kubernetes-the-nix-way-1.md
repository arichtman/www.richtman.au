+++
title = "Kubernetes the Nix Way - Part 1"
date = 2024-06-23T13:12:58+10:00
description = "A Rocky start"
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "nixos", "kubernetes", "k8s", "k8s-nix-way" ]
+++

Note: This entry is while I was still finding the series' feet.
Please try the subsequent articles as they are more focussed and better presented.

## Kubernetes the Nix Way - Part 1

We'll keep using SnowfallOrg's `lib`, I find it convenient for wiring stuff up.
Be warned though, the convenience stopped me from learning quite a few foundationals of Nix.

Our first step is going to be getting `etcd` up and running.
For now I'm going to set each component into it's own `nix` file.
Hopefully that stays nice and encapsulated, though cross-references might be spaghetti.

I'll also add a general library `nix` file.

Ideally I'd like certificate generation to be Nixified.
I have seen an `mkCert` function about, not sure how deterministic it can be when time is essential.

I tripped over the whole git-untracked-doesn't-apply for like the 20th time.
I further realized that only `default.nix` is getting applied.
So my options are either to wire the other module files in as options set from `default.nix` or maybe use `import`?
For now I'll simply `import` them.
If it makes sense to refactor them later I can do it after it's functional.

Thinking about the cluster, it's possible to bootstrap `etcd` and even the API server using static pods?
Do I want to do this?
In some sense there's always going to be a boundary where Kubernetes wants to control it's resources.
On the other had Nix is pretty good and not as fiddly to debug as containers.
I wonder also about performance characteristics.

I had a poke about gVisor also, to see if that would make sense to deploy in place of `containerd`.
It looks like we still use `containerd` we just add gVisor's `runsc` as a plugin.
I've decided not to poke that beast for now as I have enough on my plate.
Eventually though I'd like to default all containers to gVisor.
I may poke `youki` or something later on as well.

I located the NixOS module `virtualization.containerd`, I'll use this for a building block.
I coincidentally realised I quite likely _could_ have modified the configuration as I wanted.
I'm also realizing I'm going to have to learn quite a bit of `systemd` for this.

The systemd service for `containerd` seem to be in and fine.
I pop a nix shell with `nerdctl` in there to poke it.
I launch a test `busybox` image with `sleep 30` but it just hangs with status of _Created_.
Checking `journalctl` I can see we've the same issue as before - there is no "default" CNI config.
Which is annoying since presumably there's a simple config that'll let you run containers locally.
It's what they do out of the box anyways with virtual networking!
I wonder if it's because there's a config option pointing to a CNI config dir, and if we nulled/removed that it'd work.

I note that the `/etc/cni/net.d` directory is closed to my `nixos` user.
I'll check the options to see about world-readable mode, since it's nothing sensitive anyway.

I'm trying to put together a minimal CNI config that'll allow containers to run locally.
From there I think I can bootstrap Cilium.
I'm using the provided `ctr` tool to launch and monitor containers.
Almost all of these can be shortened with aliases but they're full here for clarity.

```bash
# Pull
ctr image pull docker.io/library/alpine:latest
# Create to witness long-running
ctr container create docker.io/library/alpine:latest test sleep 2000
# Create to see output on stdout
ctr container create docker.io/library/alpine:latest test echo foo
# See the container
ctr container ls
# Start the container
ctr task start test
# See if it's running
ctr task ls
# Check logs
journalctl -xeu containerd
# Cleanup

# Remove stuck task
ctr task kill -s SIGKILL test
# Remove container
ctr container rm $(ctr container ls --quiet)
# or
ctr container rm test
# Remove image (yes, this is not granular)
ctr images prune --all
```

Aha! Paring the CNI config back to purely a loopback device seems to work, I was able to get containers running using `ctr`
This gives me confidence the CRI will operate successfully underneath the Kubelet.

## References

- [State of work](https://github.com/arichtman/nix/commit/db9502516bd5a226b9084e281a86b7b5a7208e3a)
- [gVisor Containerd docs](https://gvisor.dev/docs/user_guide/containerd/quick_start/)
- [Youki repo](https://github.com/containers/youki)
- [CNI Plugins Bridge docs](https://www.cni.dev/plugins/current/main/bridge/)
- [StackExchange ctr question](https://devops.stackexchange.com/questions/16784/how-to-check-running-containers-with-containerd)
- [Ti Nguyen's TAP toot tip](https://ipv6.social/@litchralee_v6/112664316708729981)
- [CTR lesson](https://labs.iximiuz.com/courses/containerd-cli/ctr/image-management#what-is-ctr)
- [StackOverflow on force-killing ctr tasks](https://stackoverflow.com/questions/67171982/how-to-stop-container-in-containerd-ctr)

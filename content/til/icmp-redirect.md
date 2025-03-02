+++
title = "Systemd-resolved Configuration Source"
date = 2025-03-02
[taxonomies]
categories = [ "TIL" ]
tags = [ "networking", "dns", "systemd" ]
+++

Systemd-resolved orchestrates the well-known `/etc/resolv.conf` file, so that it's local service is used for DNS queries.
Configuration for the service is a usual combination of `/etc/systemd/resolved.conf` and drop-ins in `/etc/systemd/resolved.conf.d/`.
The resultant actual resolution configuration is stored at `/run/systemd/resolve/resolv.conf`.
This is useful specifically in Kubernetes contexts with CoreDNS, where you have a local stub resolver for the nodes,
but you don't want pods attempting to access DNS on the loopback interface, as nothing will be listening, and it won't be routed to the host.

## References

- [ArchWiki](https://wiki.archlinux.org/title/Systemd-resolved)
- [CoreDNS Loop Troubleshooting](https://coredns.io/plugins/loop/#troubleshooting-loops-in-kubernetes-clusters)

+++
title = "Adding mDNS support to OPNsense"
description = "The things we do for DNS..."
date = 2024-12-07T19:05:57+10:00
[taxonomies]
categories = [ "Technical" ]
tags = [ "opnsense", "dns", "mdns", "networking" ]
+++

## Problem

We want to be able to easily refer to machines on our local network by their hostnames.

[Just take me to the fix!](#solution)

## Analysis

DNS resolution path determination on Linux is already a mess.
Some things don't respect `nsswitch.conf`, others try to take over (looking at you, `systemd-resolved`).
Specifically for me, GoLang, when compiled without `cgo`, uses it's own DNS stack.
This means that `kubectl` commands fail to resolve hostnames.
So we need something more enforced than application-level or machine-level configuration.

We're already trapping all outbound DNS traffic in order to enforce filtering and upgrade to DNS-over-TLS (DoT).
This ensures that regardless of which resolvers clients try to use, they're guaranteed to hit our non-authoritative Unbound DNS service.
This guarantees that they'll see any overrides (AKA DNS poisoning) that we put in.

ISC DHCPv4 has an option to automatically register client leases as DNS overrides.
ISC DHCP is deprecated in favor of Kea.
Kea DHCPv4 does not have this option.

Furthermore, IPv6 SLAAC doesn't require registration with the server.
No registration means OPNsense remains blind to the machines somewhat.
So no DNS overrides/registration can be performed.

OPNsense doesn't resolve mDNS, however.

OPNsense is tied to it's own package repository, which only has stuff that's been packaged for OPNsense.
Ports are BSD's version of package management but from source.
Ports seem to be maintained against a specific BSD distro, much like packages are.
Luckily, there is a set of ports maintained for OPNsense.

For the core of the problem, we really only need mDNS *resolution* on OPNsense.
However, turns out the mDNS daemon and the rest of it is a requirement for the ports that add resolution.
It's also a nice-to-have, completing the set of mDNS-enabled machines on the network.

We have a couple of options here.
We can use `avahi`[`-app`], or the Apple OSS `mDNSResponder`.
I chose to stick with Avahi for consistency and control.

## Solution

### mDNS responder and pre-requisites

1. Clone the ports repo, or download a release and decompress it.
1. Install `avahi` meta-package `cd ports/net/avahi && make`.
   About a zillion things will fly by you, some of them with terrifying dates and version numbers.
   Be brave.
   You did snapshot your VM before this, right?
1. Avahi requires `dbus`, so `service dbus start`.
1. Directly test the Avahi daemon `/usr/local/sbin/avahi-daemon`.
1. Test mDNS resolution from OPNsense for another machine `avahi-resolve-host-name mum.local`.
   Test mDNS resolution from another machine `avahi-resolve-host-name opnsense.local`.
   If this is working, proceed onwards.
   If you want to investigate errors like I had to about it failing to start, `/usr/local/sbin/avahi-daemon --debug`.
1. Fire it up as an rc daemon `service avahi-daemon start`, and check with `/usr/local/sbin/avahi-daemon -c`.
1. Repeat the test of resolution from another machine.
   If that's all working, proceed.
1. Set the rc daemons to start automatically: `service dbus enable`, `service avahi-dnsconfd enable`, `service avahi-daemon enable`.

### mDNS resolution

1. Install `nss_mdns` port `cd dns/nss_mdns && make`.
1. Sit back and watch history scroll by.
1. Amend `/etc/nsswitch.conf`'s `hosts` line to read:
   `hosts: files mdns_minimal [NOTFOUND=return] dns mdns`
1. Now anything that respects `nsswitch.conf` will use mDNS!

Super unfortunately, basically nothing we need will use this.
I may go into a future post about setting up authoritative DNS but tbh I expect it to be well covered already.

## References

- [FreeBSD forums on nsswitch.conf mDNS](https://forums.freebsd.org/threads/what-are-appropriate-settings-for-etc-nsswitch-conf-and-mdns.58413/)
- [Daemonforums missing DBUS](https://daemonforums.org/showthread.php?t=5502)
- [Fediverse help courtesy @TomAoki@bsd.cafe](https://mastodon.bsd.cafe/@TomAoki/113606025862058548)
- [FreeBSD docs](https://docs.freebsd.org/en/books/handbook/config/#configtuning-rcd)
- [FreeBSD manual on nsswitch.conf](https://man.freebsd.org/cgi/man.cgi?query=nsswitch.conf&apropos=0&sektion=5&manpath=FreeBSD+14.1-RELEASE&arch=default&format=html)
- [OPNsense ports](https://github.com/opnsense/ports)

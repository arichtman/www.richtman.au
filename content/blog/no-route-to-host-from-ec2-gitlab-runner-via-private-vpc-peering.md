+++
title = "No Route to Host from EC2 GitLab Runner via Private VPC Peering"
date = 2022-11-02T08:54:20Z
description = "Follow along a magical adventure of routing"
[taxonomies]
#categories = [ "Technical", "Troubleshooting" ]
tags = [ "ec2", "aws", "gitlab", "containers", "docker-engine", "docker", "networking", "routing", "private-routing" ]
+++

## Problem

We're on AWS, on a GitLab runner (EC2), trying to access a service, hosted on EC2, via private networking, over a VPC peering.
As one does, surely.
It's been fine all day but has now started timing out in CI.

[Just take me to the fix!](#solution)

## Analysis

No networking changes have been made.
Access analyzer says the path is clear.
Let's check each stage manually from end to end.
Source SG has unlimited egress to private IP ranges.
Source route table checks out with destination CIDR set to the Peering Connection Id.
Source NACL is open.
Peering is live with no issues.
Dest NACL is open.
Dest route table has local set correctly.
Security group rule ingress is open to private IPs.
Service is running on destination instance.

Let's poke on the runner machine.

```bash
$ host artifactory-bne.silverrail.io
artifactory-bne.silverrail.io has address 172.31.151.55
$ curl -IL https://artifactory-bne.silverrail.io
curl: (7) Failed to connect to artifactory-bne.silverrail.io port 443 after 3064 ms: No route to host
$ ping artifactory-bne.silverrail.io
PING artifactory-bne.silverrail.io (172.31.151.55) 56(84) bytes of data.
From ip-172-31-0-1.ap-southeast-2.compute.internal (172.31.0.1) icmp_seq=1 Destination Host Unreachable
...
```

Ok so DNS looks OK.
Let's try public IP access.

```bash
$ host artifactory-bne.silverrail.io 1.1.1.1
Using domain server:
Name: 1.1.1.1
Address: 1.1.1.1#53
Aliases:

artifactory-bne.silverrail.io has address 54.66.147.130
$ curl -kL https://54.66.147.130
<!doctype html><html lang=en><head>
~ snip ~
$ traceroute artifactory-bne.silverrail.io
traceroute to artifactory-bne.silverrail.io (172.31.151.55), 30 hops max, 60 byte packets
 1  ip-172-31-0-1.ap-southeast-2.compute.internal (172.31.0.1)  3069.132 ms !H  3069.090 ms !H  3069.081 ms
```

We've determined that it's definitely working via public routing.
But what could be fouling it?
Could it be our Allow/Denylists?

```bash
$ cat /etc/hosts.allow
#
# hosts.allow   This file contains access rules which are used to
#               allow or deny connections to network services that
#               either use the tcp_wrappers library or that have been
#               started through a tcp_wrappers-enabled xinetd.
#
#               See 'man 5 hosts_options' and 'man 5 hosts_access'
#               for information on rule syntax.
#               See 'man tcpd' for information on tcp_wrappers
#
$ cat /etc/hosts.deny
#
# hosts.deny    This file contains access rules which are used to
#               deny connections to network services that either use
#               the tcp_wrappers library or that have been
#               started through a tcp_wrappers-enabled xinetd.
#
#               The rules in this file can also be set up in
#               /etc/hosts.allow with a 'deny' option instead.
#
#               See 'man 5 hosts_options' and 'man 5 hosts_access'
#               for information on rule syntax.
#               See 'man tcpd' for information on tcp_wrappers
#
```

Nope, empty.
Let's see what interfaces are configured, maybe it's getting the wrong one.

```bash
$ ifconfig
br-368fedb58e20: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.23.0.1  netmask 255.255.0.0  broadcast 172.23.255.255
        inet6 fe80::42:d9ff:fe2d:eab5  prefixlen 64  scopeid 0x20<link>
        ether 02:42:d9:2d:ea:b5  txqueuelen 0  (Ethernet)
        RX packets 10  bytes 2293 (2.2 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 42  bytes 4101 (4.0 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

br-5807d8e7d5ef: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.20.0.1  netmask 255.255.0.0  broadcast 172.20.255.255
        inet6 fe80::42:4fff:fe68:eb30  prefixlen 64  scopeid 0x20<link>
        ether 02:42:4f:68:eb:30  txqueuelen 0  (Ethernet)
        RX packets 2731747  bytes 3913753552 (3.6 GiB)
        RX errors 0  dropped 1172  overruns 0  frame 0
        TX packets 263683  bytes 61385014 (58.5 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

br-5ad89dd3f7a1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.30.0.1  netmask 255.255.0.0  broadcast 172.30.255.255
        inet6 fe80::42:eff:fe99:1150  prefixlen 64  scopeid 0x20<link>
        ether 02:42:0e:99:11:50  txqueuelen 0  (Ethernet)
        RX packets 67  bytes 6726 (6.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 87  bytes 278446 (271.9 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
~ about 20 more like this ~
br-e8395baf4d8b: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.31.0.1  netmask 255.255.0.0  broadcast 172.31.255.255
        inet6 fe80::42:74ff:fe43:3f21  prefixlen 64  scopeid 0x20<link>
        ether 02:42:74:43:3f:21  txqueuelen 0  (Ethernet)
        RX packets 60  bytes 4812 (4.6 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 60  bytes 4812 (4.6 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
$ ip route
default via 172.18.2.129 dev eth0
169.254.169.254 dev eth0
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
172.18.2.128/26 dev eth0 proto kernel scope link src 172.18.2.172
172.19.0.0/16 dev br-821cfe9bd141 proto kernel scope link src 172.19.0.1
172.20.0.0/16 dev br-5807d8e7d5ef proto kernel scope link src 172.20.0.1
172.23.0.0/16 dev br-368fedb58e20 proto kernel scope link src 172.23.0.1
172.24.0.0/16 dev br-71ad0fdf7da8 proto kernel scope link src 172.24.0.1
172.25.0.0/16 dev br-951a19746eac proto kernel scope link src 172.25.0.1
172.26.0.0/16 dev br-5ea53645932b proto kernel scope link src 172.26.0.1
172.27.0.0/16 dev br-6d2c872f4b78 proto kernel scope link src 172.27.0.1
172.28.0.0/16 dev br-f9b54fb457b0 proto kernel scope link src 172.28.0.1
172.29.0.0/16 dev br-c218a698d5d2 proto kernel scope link src 172.29.0.1
172.30.0.0/16 dev br-5ad89dd3f7a1 proto kernel scope link src 172.30.0.1
172.31.0.0/16 dev br-e8395baf4d8b proto kernel scope link src 172.31.0.1
192.168.0.0/20 dev br-986349f1cf76 proto kernel scope link src 192.168.0.1 linkdown
```

Ok now I'm super suss.
What has Docker been doing to the networking here...

```bash
$ docker network ls
NETWORK ID     NAME                                                                  DRIVER    SCOPE
1349ab7b2802   bridge                                                                bridge    local
821cfe9bd141   brisbane-office-industry-data-management-system-back-end-33_default   bridge    local
5807d8e7d5ef   brisbane-office-industry-data-management-system-back-end-34_default   bridge    local
368fedb58e20   brisbane-office-industry-data-management-system-back-end-37_default   bridge    local
71ad0fdf7da8   brisbane-office-industry-data-management-system-back-end-38_default   bridge    local
951a19746eac   brisbane-office-industry-data-management-system-back-end-39_default   bridge    local
5ea53645932b   brisbane-office-industry-data-management-system-back-end-40_default   bridge    local
6d2c872f4b78   brisbane-office-industry-data-management-system-back-end-41_default   bridge    local
f9b54fb457b0   brisbane-office-industry-data-management-system-back-end-43_default   bridge    local
c218a698d5d2   brisbane-office-industry-data-management-system-back-end-45_default   bridge    local
5ad89dd3f7a1   brisbane-office-industry-data-management-system-back-end-46_default   bridge    local
e8395baf4d8b   brisbane-office-industry-data-management-system-back-end-47_default   bridge    local
3af20b4a9908   host                                                                  host      local
711eaca3cb79   none                                                                  null      local
```

I recognise those slugs...

## Solution

Each of the Docker networks must have a virtual network interface.
Docker messes with `iptables` to route traffic to them.
If it doesn't clear up previous virtual networks, it'll just keep taking new private IP ranges.
Eventually, the private IP range may climb high enough to interfere with one's actual routing.
However simply removing the network won't work if it still has endpoints pointing to containers.

```bash
$ NETWORK_SLUGS=$(docker network ls --filter driver=bridge --filter type=custom --format "{{.ID}}" --no-trunc)

$ for NETWORK_SLUG in $NETWORK_SLUGS
  do
    CONTAINER_NAMES=$(docker network inspect $NETWORK_SLUG | jq -r " .[].Containers | .[].Name ")
    for CONTAINER_NAME in $CONTAINER_NAMES
      do
        docker network disconnect --force $NETWORK_SLUG $CONTAINER_NAME
      done
      docker network rm $NETWORK_SLUG
  done

$ docker network ls
```

Jinkies gang, it turns out it was old man DevOps all along.
For future management we'll look into our `docker compose down` and `docker system prune` commands to see how thoroughly they're tidying up after themselves.

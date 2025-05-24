+++
title = "Kubernetes Networking and Cilium"
description = "Summary of the book"
[taxonomies]
categories = [ "Personal", "Meta" ]
tags = [ "reference", "book", "professional-development", "summary" ]
+++

# Kubernetes Networking and Cilium

This book is quite short so I won't be labelling each topic/section.

Author's notes will be _AN:_.

## Preface

Book is aimed at network engineers, CCNA-level assumed.

No more configuring individual nodes, declarative config.

DHCP replaced with IPAM, three modes

Kubernetes-host scope (AKA per-Node `PodCIDR`):
Cluster-wide prefix configured, Kubernetes divides that up for nodes.
Cilium assigns IPs from _Pod_'s host _Node_ `PodCIDR`.
Once the pool is exhausted, it cannot be expanded.

Cluster-scope:
Cilium now responsible for node assignment of `PodCIDR`.
Can have multiple prefixes, so expansion possible.

Multi-pool:
Most flexible, annotations can drive assignment of both `PodCIDR` and Pod IP from specific pools.
Nodes can have PodCIDRs dynamically added as needed.

IP addresses are now more than ever not identity, as Pods in different administrative domains (i.e. namespaces) can have IPs from the same pool.
_AN: could probably manage IP segregation using multi-pool_

DNS is not a responsibility of the CNI.
Though both forward and reverse domains should be available.
Forward example: `my-services.my-namespace.svc.my-cluster.local`.
Reverse example: `10-244-1-234.my-namespace.pod.my-cluster.local`.
_AN: reverse not the typical `in-addr.arpa` stuff, and `.local` is usually mDNS so, bit odd._

Two inter-pod/East-West communication modes, overlay/encapsulation and native/direct.
Overlays are default and often VXLAN but sometimes GENEVE or others.
Overlays are constructed as tunnels between the nodes.
_AN: this seems like it'll scale poorly with node count.
There's also maybe some perf cost, but they do allow clusters to span different L2 networks/subnets,
though this is also apparently possible via BGP._

Overlay pros:

- Decoupled from underlying network - no requirements of it.
- As above but specifically it's possible to use a larger range than is otherwise available.
- Auto configuration and simpliciy - nodes join the overlay no fuss.
  _AN: I'd quibble with simplicity on this one._

Overlay drawbacks: fifty-byte per-packet overhead per 1500 bytes on VXLAN without jumbo frames.
_AN: this is only one and incredibly specific, and ignores encapsulation processing and latency, though possibly it's offloaded and negligible._

Labels vs annotations:
Labels are for selecting, grouping, and operating on things.
Annotations are institutional knowledge about a resource.
_AN: in the context of operators, I also equate annotations with arguments to the operator._

Firewall rules are now _Network Policies_, though we get a lot more context to operate on than traditional IP+Port.
Being able to make decisions based on administrative domain (namespace), as well as pod labels, subtly changes it to _Identity-based Security_.
Layer 7 (including HTTP) policies are now also possible, though they cannot entirely subsume or obviate web-facing firewalls, nor IDS/IPS.

East-West load balancing is done using a _Service_ of type `ClusterIP` (the default).
Key differential here, Kubernetes core is responsible for _Service_ IPAM, **not** the CNI which handles _Pods_.

North-South load balancing has two options; `NodePort` and `LoadBalancer`.
_AN: practically I've really only ever seen LB ingress, NP is cumbersome._
LB providers are separate to the CNI, though Cilium can act as one via LB-IPAM feature.
Cilium can also offer traffic ingress, by acting as an ingress controller.
Anyways, `Ingress` is so yesterday, `Gateway` API is where it's at.
Cilium can also offer traffic ingress, by acting as a gateway controller.
_AN: hot girl shit._

You _could_ roll your own BGP, but Cilium does that too!
Usually this is used to peer with _Top-of-Rack_ (ToR) routers.
If you don't have or want BGP, you _can_ do ingress via _Virtual-IP_ (VIP) by way of gratuitous ARP.
_AN: At the time of writing I don't think they offered IPv6 _Neighbor Discover_ for this.
Also I never did work out why native routing didn't just put the assigned _Pod_ IPs on the host interface._

Once packets are outside the cluster, there's no namespace or labels etc.
If you need to know the workload making the request, you can use `EgressGateway`.
This forces the outbound traffic via dedicated node(s), so you know the IP, at least.
_AN: incredibly clunky, but I get it. Wonder if v6 headers or even VLAN tags could work._

_Kube-Proxy_ isn't actually a proxy, it just orchestrates `iptables` to create in-cluster VIPs and route traffic.
There is apparently an `ipvs` mode that uses `netfilter` but it's still an ornery approach.
eBPF lets you insert small programs all along the Kernel paths, and performs much better.

Troubleshooting Tooling Transition:

- Check TCP/IP connectivitity: `ping/traceroute` -> `ping`
- Check HTTP connectivity: `curl` -> `curl`
- Check network status: IOS CLI -> `kubectl/cilium`
- Capture network logs: IOS CLI and Syslog -> `kubectl logs`
- Capture traffic patterns & bandwidth: NetFlow/sFlow -> Hubble
- Analyse network traffic: `tcpdump`/WireShark -> `tcpdump`/WireShark/Hubble
- Generate traffic for testing: `iperf` -> `iperf`

Rather than logging into a router and running commands, deploy `nicolaka/netshoot` and run from there.
`kubectl debug backend-pod -it --image=nicolaka/netshoot -- tcpdump`

Hubble is like a mashup of NetFlow and WireShark, and has both web GUI and CLI.
`hubble observe --from-pod my-namespace/my-pod`

Network policies have three enforcement modes; `never`, `always`, and `default`.
`never` is what you think, used for audit mode to see what policies you might want to add.
`default` means all endpoints are initially unrestricted.
As soon as a rule matches, they enter enforcement and you must have a policy that allowlists traffic for anything to flow.
`always` is what you think.

Two traffic encryption options; IPsec and WireGuard.
IPsec gives you more granular control, but also more responsibility.
_AN: we stan wg._

Connecting clusters is the usual at an IP level, but with vanilla k8s, across the cluster boundary no namespace or label information flows.
Cilium _Cluster Mesh_ federates the clusters at a Cilium level, and allows even cross-cluster load balancing.

Traditional QoS isn't quite dead but it's now pod annotations like `kubernetes.io/egress-bandwidth=10M`.

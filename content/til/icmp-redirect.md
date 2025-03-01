+++
title = "ICMP Redirect"
date = 2025-03-01
[taxonomies]
categories = [ "TIL" ]
tags = [ "networking", "icmp" ]
+++

Gateways can offer something of a dynamic redirect using an ICMP feature.
If a gateway receives a packet on an interface with an onward destination, and the routing table says the next hop
is back out the same interface to the same network, it may send an ICMP redirect.
This tells the traffic originator to direct future traffic for that destination directly to that gateway instead.

Since obeying the redirect is client-side it's presumably optional and configurable.
There appear to be some security concerns with this also.

## References

- [Cisco documentation](https://www.cisco.com/c/en/us/support/docs/ip/routing-information-protocol-rip/13714-43.html)
- [ICMP RFC](https://www.rfc-editor.org/rfc/rfc792)

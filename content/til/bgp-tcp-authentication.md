+++
title = "BGP/TCP Authentication"
date = 2025-04-17
[taxonomies]
categories = [ "TIL" ]
tags = [ "networking", "bgp", "security", "auth", "authentication" ]
+++

BGP has an authentication option that's based on a TCP authentication RFC.
A pre-shared key (PSK) is used to initiate the peering, but support is there for rekeying an existing peering.
The key, along with some values from the TCP packet content is hashed and transmitted in packet headers.
This prevents tampering with the packet contents, and replays.

## References

- [Cilium Weekly 39 video](https://www.youtube.com/watch?v=zgn4qjNOlsI)
- [TCP Authentication RFC](https://datatracker.ietf.org/doc/html/rfc5925)

+++
title = "Networking Intermediate Cheat Sheet"
date = 2025-03-02T18:45:46+10:00
description = "Invisible forces"
[taxonomies]
categories = [ "Technical" ]
tags = [ "reference" ]
+++

## TCPdump

Select interface: `-i eno1`

Select direction: `-Q in|out|inout`

Select IPv6: `ip6`

Source/dest: `src|dst`

No DNS lookups/replacement: `-n`

Show MACs: `-e`

## Netcat

Scan only: `-z`

Wait: `-w 2`

IP: `-6`

Verbose: `-v`

UDP: `-u`
I'm really not sure how effective UDP scanning is since there's no return packets I think.

## ICMP

Some `ping` commands use UDP apparently, maybe BSD/Mac, mind that.

Tcpdump filter: `icmp6[icmp6type]=icmp6-echo[reply]`

Set size: `-s 1024`

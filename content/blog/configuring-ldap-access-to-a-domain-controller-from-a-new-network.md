+++
title = "Configuring LDAP access to a domain controller from a new network"
date = "2022-11-03 02:09:05+00:00"
description = "Practical steps when moving client machines to separate networks to enable auth access to domain controllers ."
[taxonomies]
categories = [ "Technical" ]
tags = [ "domain-controller", "aws", "windows", "microsoft" ]
+++

## Problem

You're moving your Windows desktops to a new network but you still need to be able to roll Group Policy and authentication off your Domain Controllers in the old network.

## Analysis

Domain controllers use a combination of DNS and SMB to manage their authentication and service discovery process.
By enabling these along with the requisite network connectivity we are able to maintain functionality across networks.

## Solution

**Note**: Please read the entirety of the procedure before commencing. No warranty is implied with this information. As always, back up everything and untested backups aren't backups.

This is pretty practical and rough but it works, I'm no MS Engineer. Happy to take feedback!

For DNS we need service discovery endpoints and then actual A records for the domain controllers themselves.
For UNC paths and retrieval of Group Policy, we need some apex domain A records and local settings 

First we're going to pilfer the old DNS entries.
Run this and take note of the outputs.
We'll use this to construct DNS records for our new network.

```Powershell
$Domain = "au.local"
$DomainControllerAliases = @(
    "dca",
    "dcb"
)
$DomainControllerAliases | ForEach{ nslookup -type=a "$_.$Domain" }
nslookup -type=srv _ldap._tcp.au.local
```

Next we need to enable network level access to the domain controller.
Bare minimum* on the DC is going to be:

- SMB: TCP ingress on 445
- DNS: UDP ingress on 53
- LDAP: TCP ingress on 3389
- Return traffic: Egress above 32-thousand through 64-thousand-whatever*

In my case it was appropriate to grant all TCP ingress and egress with source/target CIDR of our private network range.
YMMV, consult your Cyber folk, threat model, or architects to see what's appropriate.

Now we configure our DNS on the new network to poison our DNS for the local domain.
Enter the SRV and A records we captured earlier.
Add an additonal A record to the apex of the local domain with the IPs of your domain controllers.
That might look like `                  14400 A     198.51.100.1`.

The final step involves ensuring that your machine's configured to provide authentication when trying to access the domain controller's DFS/shared volumes via UNC path.
It's probably best to push this change via GPO *before* moving any client machines to make life easier, but it's recoverable.
See the reference on UNC path local policy for details.

You should now be able to run `gpupdate` with no issues.

Should you wish to run more comprehensive tests from your client machine(s), install [RSAT](https://www.microsoft.com/en-us/download/details.aspx?id=45520) and try the following.

```Powershell
$DomainControllerAliases | ForEach {DCDIAG /TEST:DNS /V /E /S:$_ }
```

## Notes

- Yes it's probably not the correct/best/complete way to do it, but it works and if it helps someone get off the ground I'm ok with it.
- Yes, it's possible to cascade the DNS through the old network's resolver, however we're expressly trying to decommission the old network.
- I'm sure there are other services that we could enable by copying more SRV records, but again this is just the basics.
- Full list of ports for DC features is more like: 53, 88, 137, 139, 389, 445, 464, 3268, 636, 3269.
- The return traffic bit is in case of stateless firewalls, but I've only done this with stateful rules so expect to have to adjust for your circumstances.

## References

- [UNC path local policy](http://woshub.com/cant-access-domain-sysvol-netlogon-folders/)
- [Microsoft on Domain Controller location mechanisms](https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/how-domain-controllers-are-located)

+++
title = "WSL2 NixOS Port Access"
date = 2022-11-07T12:24:04Z
description = "Fixing port access from Windows to NixOS on WSL2"
[taxonomies]
categories = [ "Technical", "Troubleshooting" ]
tags = [ "wsl2", "nixos", "networking" ]
+++

## Problem

We want to run a server on our NixOS install on WSL2.
Specifically, we'd like to view our Zola site locally without having to push a branch and open an MR.
However, when we try to connect to the service it times out.
It seems Windows is holding onto our low end port numbers for dynamic use.
This may be the result of a botched OS patch or Hyper-V misconfiguration.
Either way let's get a-fixin'

## Solution

Running with elevated privileges:

```Powershell
Set-NetTCPSetting -DynamicPortRangeStartPort 10240 -DynamicPortRangeNumberOfPorts $(65535 - 10240)
```

You'll now have to restart your PC but you should be good to go after that.

## References

- [SuperUser](https://superuser.com/questions/1469431/cant-open-port-even-there-is-no-other-applications-are-listening-on-it-windows/1671709#1671709)
- [Windows OS Hub](http://woshub.com/powershell-configure-windows-networking/)

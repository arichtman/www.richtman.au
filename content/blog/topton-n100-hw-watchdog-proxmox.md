+++
title = "Topton N100 Hardware Watchdog Configuration for Proxmox"
date = 2024-06-22T14:06:42+10:00
description = "Poor man's HA"
draft = true
[taxonomies]
categories = [ "Technical", "Troubleshooting" ]
tags = [ "n100", "linux", "proxmox", "ha", "topton", "watchdog" ]
+++

## Problem

The backbone of my home solution is a Topton N100.
This machine includes my virtualized router.
The machine periodically becomes totally unresponsive.
A hard reset is the only thing that restores functionality.

Outages at home are not critical as I'm not hosting any services (yet) and mobile connectivity suffices.
However, without physical access to the machine, all my services, VPN etc are offline.
This is unacceptable for remote access and maintenance.

[Just take me to the fix!](#solution)

## Analysis

Proxmox does seem to have a software watchdog enabled.

```bash
wdctl

Device:        /dev/watchdog0
Identity:      Software Watchdog [version 0]
Timeout:       10 seconds
Pre-timeout:    0 seconds
Pre-timeout governor: noop
Available pre-timeout governors: noop
```

This is obviously insufficent as the machine remained stalled.
Checking the Proxmox HA wiki it also notes that software watchdogs are less reliable.
This is logical and echoes similar sentiments online.

Topton claim their N100 machine supports a watchdog.
Presumably this is a hardware feature.
Proxmox disables all hardware watchdogs by default, citing them as footguns if not properly initialized.
This makes a fair bit of sense, as it'd be all too easy to misconfigure it and get stuck in a hard reset loop, unable to disable the watchdog.

Poking about the kernel buffer we see that NMI watchdog is already operational `dmesg | grep -i watchdog`.
This is a pure kernel watchdog, so not what we want I think.
I don't think we have to disable this to use the hardware watchdog.

We'll need to find which module for watchdog, and add it to `/etc/default/pve-ha-manager`
Poking around it looks like there are two common modules: `ipmi_watchdog` and `iTCO_wdt`.
Using `modprobe` I'm able to see that `iTCO_wdt` results in the addition of `/dev/watchdog1`.
Inspecting this using `wdctl /dev/watchdog1` confirms that it is using the module, just not automatically on boot.

```bash
modprobe iTCO_wdt

ls /dev/watchdog*

/dev/watchdog
/dev/watchdog0
/dev/watchdog1

wdctl /dev/watchdog1

Device:        /dev/watchdog1
Identity:      iTCO_wdt [version 6]
Timeout:       30 seconds
Timeleft:      29 seconds
Pre-timeout:    0 seconds
FLAG           DESCRIPTION               STATUS BOOT-STATUS
KEEPALIVEPING  Keep alive ping reply          1           0
MAGICCLOSE     Supports magic close char      0           0
SETTIMEOUT     Set timeout (in seconds)       0           0

```

## Solution

To set this module on boot we amend the Proxmox HA config.

`/etc/default/pve-ha-manager`:

```ini
# select watchdog module (default is softdog)
WATCHDOG_MODULE=iTCO_wdt
```

Optionally, we can tune some settings.
The `softdog` is really not necessary but left here for people who may be using it.
I like `nowayout` set true as I'd rather reboot than leave it in a zombie state.

`/etc/modprobe.d/watchdog.conf`:

```ini
options iTCO_wdt nowayout=1 heartbeat=600
options softdog nowayout=1
```

The Systemd settings are pulled from `/etc/systemd/system.conf`.
Adjust these as you see fit, or not at all.
I wound the runtime duration out to avoid any erroneous restarts.

`/etc/systemd/system.conf.d/10-watchdog.conf`:

```ini
[Manager]
RuntimeWatchdogSec=30
#RuntimeWatchdogPreSec=off
#RuntimeWatchdogPreGovernor=
#RebootWatchdogSec=10min
#KExecWatchdogSec=off
#WatchdogDevice=
```

Reboot and confirm.

```bash
cat /sys/class/watchdog/watchdog0/state

active

wdctl

Device:        /dev/watchdog0
Identity:      iTCO_wdt [version 0]
Timeout:       30 seconds
Timeleft:      30 seconds

lsof /dev/watchdog0

COMMAND PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
systemd   1 root   56w   CHR  244,0      0t0  883 /dev/watchdog0
```

## References

- [man(8) wdctl](https://www.man7.org/linux/man-pages/man8/wdctl.8.html)
- [man(8) watchdog](https://linux.die.net/man/8/watchdog)
- [man(5) systemd-system.conf](https://www.man7.org/linux/man-pages/man5/systemd-system.conf.5.html)
- [Systemd for Administrators, XV](https://0pointer.de/blog/projects/watchdog.html)
- [Proxmox wiki on HA](https://pve.proxmox.com/wiki/High_Availability)
- [Topton machine specifications](https://www.toptonpc.com/product/12th-gen-alder-lake-2-5g-soft-router-intei-i7-1265u/)
- [Proxmox forum post](https://forum.proxmox.com/threads/howto-setup-watchdog.54582/)
- [Linux kernel watchdog docs](https://www.kernel.org/doc/html/latest/admin-guide/lockup-watchdogs.html)
- [Linux kernel watchdog API docs](https://www.kernel.org/doc/html/latest/watchdog/watchdog-api.html)
- [Watchdog Ubuntu blog post](https://blog.heckel.io/2020/10/08/reliably-rebooting-ubuntu-using-watchdogs/)

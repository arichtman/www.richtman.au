+++
title = "Recovering NixOS on WSL2"
date = 2023-07-09T13:26:03+10:00
description = "No part of this went well"
[taxonomies]
#categories = [ "Technical", "Troubleshooting" ]
tags = [ "nixos", "wsl", "wsl2" ]
+++

# Recovering WSL2 NixOS

## Problem

A nixos rebuild has borked the distro.

```powershell
> wsl

/nix/store/701bd06kvch5kqzdap5rdcwdi7pxv5mc-syschdemd/bin/.syschdemd-wrapped: line 74: getent: command not found
```

[Just take me to the fix!](#solution)

## Analysis

Looks like we've removed something critical.
`getent` is a very low level tool from what I know.
I believe it's a wrapper to inspect groups and users (probably more) on the system.

```Powershell
# Let's try a full reboot first.

> wsl --terminate NixOS

> wsl

[Same error]

# Hmm no luck.
# Playing all my tier 1 cards, I try a WSL update, in case there's something there.

> wsl --update

Checking for updates.
The most recent version of Windows Subsystem for Linux is already installed.

# Ok let's check wsl2 for options.
# Maybe we can boot into the recovery bit and roll back a generation on the system profile.

> wsl --help

[Snip]

# Hmmm nothing obvious here.
# Maybe if we try different shell types we'll get a session that doesn't depend on `getent`.

> wsl --shell-type none

[Same error]

> wsl --system

[Same error]

> wsl --debug-shell

Running the debug shell requires running wsl.exe as Administrator.

# Ok easy done

> wsl --debug-shell

Welcome to CBL-Mariner 2.0.20230107 (x86_64) - Kernel 5.15.90.1-microsoft-standard-WSL2 (hvc1)
bruce-banner login: root (automatic login)

root@bruce-banner [ ~ ]#
```

Ah, right. This is the entire WSL2 virtual appliance.
It's probably not fixable from here unless we're mounting the distro's files.
Which seems excessive, let's see if we can weasel our way in.

<!-- TODO: escaping # for the prompt or whatever -->

```bash

> wsl -e /bin/sh

# Bingo, we're in. Now to take a look arou-

# ls

sh: ls: command not found

# Huh, guess we'll have to use tab-completion to navigate.
# I'm able to poke around the Nix var directory and locate the system and user profiles.
# I'll put these on PATH so we can get a functional shell.

# export PATH="/nix/var/nix/profiles/system-39-link/sw/bin:${PATH}"

# export PATH="/nix/var/nix/profiles/per-user/nixos/home-manager-41-link/home-path/bin:${PATH}"

# I wonder if we can just activate the home environment

# /nix/var/nix/profiles/per-user/nixos/home-manager-41-link/activate

Starting Home Manager activation
Error: USER is set to "root" but we expect "nixos"

# Unfortunately, the activation script is clever and checks our user.
# We'll just switch into one

# su -l nixos
```

My prompt immediately changes.
Halleluja, we have aliases, Bash, our environment variables.

Note that while we _can_ amend our initial entry call to WSL, but it won't put us in the customized shell.
So actually it makes sense for us to enter as `root` and hop to `nixos`.
At least for now.

At this point, I'm able to head to my flakes repository and checkout an earlier, working commit.

```bash
$ sudo nixos-rebuild switch --flake .

building the system configuration...
[1/2/11 built] building system-path: created 6671 symlinks in user environment
Failed to stop local-fs.target: Transport endpoint is not connected
See system logs and 'systemctl status local-fs.target' for details.
Failed to stop remote-fs.target: Transport endpoint is not connected
See system logs and 'systemctl status remote-fs.target' for details.
activating the configuration...
setting up /usr/share/applications...
setting up /usr/share/icons...
setting up /etc...
setting up /bin...
restarting systemd...
Failed to reload daemon: Transport endpoint is not connected
Failed to execute operation: Transport endpoint is not connected
Failed to reload daemon: Transport endpoint is not connected
setting up tmpfiles
/etc/tmpfiles.d/journal-nocow.conf:26: Failed to replace specifiers in '/var/log/journal/%m': Package not installed
/etc/tmpfiles.d/systemd.conf:23: Failed to replace specifiers in '/run/log/journal/%m': Package not installed
/etc/tmpfiles.d/systemd.conf:25: Failed to replace specifiers in '/run/log/journal/%m': Package not installed
/etc/tmpfiles.d/systemd.conf:26: Failed to replace specifiers in '/run/log/journal/%m/*.journal*': Package not installed
/etc/tmpfiles.d/systemd.conf:29: Failed to replace specifiers in '/var/log/journal/%m': Package not installed
/etc/tmpfiles.d/systemd.conf:30: Failed to replace specifiers in '/var/log/journal/%m/system.journal': Package not installed
/etc/tmpfiles.d/systemd.conf:32: Failed to replace specifiers in '/var/log/journal/%m': Package not installed
/etc/tmpfiles.d/systemd.conf:33: Failed to replace specifiers in '/var/log/journal/%m/system.journal': Package not installed
reloading the following units: dbus.service
Failed to reload dbus.service: Transport endpoint is not connected
See system logs and 'systemctl status dbus.service' for details.
Failed to start basic.target: Transport endpoint is not connected
See system logs and 'systemctl status basic.target' for details.
Failed to start cryptsetup.target: Transport endpoint is not connected
See system logs and 'systemctl status cryptsetup.target' for details.
Failed to start getty.target: Transport endpoint is not connected
See system logs and 'systemctl status getty.target' for details.
Failed to start local-fs.target: Transport endpoint is not connected
See system logs and 'systemctl status local-fs.target' for details.
Failed to start machines.target: Transport endpoint is not connected
See system logs and 'systemctl status machines.target' for details.
Failed to start multi-user.target: Transport endpoint is not connected
See system logs and 'systemctl status multi-user.target' for details.
Failed to start network-online.target: Transport endpoint is not connected
See system logs and 'systemctl status network-online.target' for details.
Failed to start paths.target: Transport endpoint is not connected
See system logs and 'systemctl status paths.target' for details.
Failed to start remote-fs.target: Transport endpoint is not connected
See system logs and 'systemctl status remote-fs.target' for details.
Failed to start slices.target: Transport endpoint is not connected
See system logs and 'systemctl status slices.target' for details.
Failed to start sockets.target: Transport endpoint is not connected
See system logs and 'systemctl status sockets.target' for details.
Failed to start swap.target: Transport endpoint is not connected
See system logs and 'systemctl status swap.target' for details.
Failed to start sysinit.target: Transport endpoint is not connected
See system logs and 'systemctl status sysinit.target' for details.
Failed to start timers.target: Transport endpoint is not connected
See system logs and 'systemctl status timers.target' for details.
warning: error(s) occurred while switching to the new configuration

# Ruh-roh

$ systemctl status local-fs.target

Warning: The unit file, source configuration file or drop-ins of local-fs.target changed on disk. Run 'systemctl daemon-reload' to reload units.
● local-fs.target - Local File Systems
     Loaded: loaded (/etc/systemd/system/local-fs.target; linked; preset: enabled)
    Drop-In: /nix/store/fgra7s4yaj4yadnyjwnxabvp4wzy92wx-system-units/local-fs.target.d
             └─overrides.conf
     Active: active since Sun 2023-07-09 09:22:18 AEST; 42min ago
       Docs: man:systemd.special(7)

# Better do what they say, maybe the rebuild has fixed it and we just need to take up the changes

$ systemctl daemon-reload

Failed to reload daemon: Access denied

$ sudo systemctl daemon-reload

Failed to reload daemon: Transport endpoint is not connected

# Hoo boy. Is our disk not mounted anymore?
# That would make some sense cause my flake config just uses a wsl module and doesn't declare any mounts

$ df -h

Filesystem      Size  Used Avail Use% Mounted on
none             16G  4.0K   16G   1% /mnt/wsl
none            459G  405G   55G  89% /usr/lib/wsl/drivers
none             16G     0   16G   0% /usr/lib/wsl/lib
/dev/sdc       1007G   87G  870G  10% /
none             16G   84K   16G   1% /mnt/wslg
rootfs           16G  1.9M   16G   1% /init
none            1.6G     0  1.6G   0% /dev
none            7.9G  260K  7.9G   1% /run
none             16G     0   16G   0% /run/lock
none             16G     0   16G   0% /run/shm
none             16G     0   16G   0% /run/user
tmpfs           4.0M     0  4.0M   0% /sys/fs/cgroup
none             16G   76K   16G   1% /mnt/wslg/versions.txt
none             16G   76K   16G   1% /mnt/wslg/doc
drvfs           459G  405G   55G  89% /mnt/c
drvfs           932G  674G  258G  73% /mnt/d
tmpfs            16G  432K   16G   1% /run/wrappers

# Uhhhh I don't even know what this is supposed to look like
# Fire up my WSL2 Ubuntu to check

$ df -h

Filesystem      Size  Used Avail Use% Mounted on
none             16G  4.0K   16G   1% /mnt/wsl
none            459G  405G   55G  89% /usr/lib/wsl/drivers
none             16G     0   16G   0% /usr/lib/wsl/lib
/dev/sdd        251G   43G  196G  18% /
none             16G   80K   16G   1% /mnt/wslg
rootfs           16G  1.9M   16G   1% /init
none            1.6G     0  1.6G   0% /dev
none             16G     0   16G   0% /run
none             16G     0   16G   0% /run/lock
none             16G   84K   16G   1% /run/shm
none             16G     0   16G   0% /run/user
tmpfs            16G     0   16G   0% /sys/fs/cgroup
none             16G   64K   16G   1% /mnt/wslg/versions.txt
none             16G   64K   16G   1% /mnt/wslg/doc
drvfs           459G  405G   55G  89% /mnt/c
drvfs           932G  674G  258G  73% /mnt/d

# That looks similar. drvfs is same, root mount is close enough, rootfs and tmpfs are same.
# Let's try a full reboot in case it's fixed now

$ exit 0; exit 0

> wsl -t NixOS

> wsl

[Original getent error]

# Nooope. Ok let's try the StackOverflow suggestions

$ fusermount -u /

fusermount: entry for / not found in /etc/mtab

$ sudo umount -l / ; exit 0

> wsl -t NixOS

> wsl

[Original getent error]
```

Alright, I'd love to work this out but:

1. The NixOS-WSL maintainer suggestion is to use the latest version
1. The entire point of Nix is being able to reproduce this
1. It's WSL. It's all kinds of niche stuff that has little support and won't be useful in future.

So I'm going to put a pin in the troubleshooting, export my actual stuff, and reimport the distro.

## Solution

1. Side-step your way into a functional session `wsl --exec /bin/sh`
1. Tab-complete to find a system profile under `/nix/var/nix/profiles`
1. Call `su --login` from the system profile directory to enter an interactive login shell session as your user
1. Pack your stuff up and ship it out
  `tar -czf my-stuff.tgz ~/important-files && cp ~/my-stuff.tgz /mnt/c/`
1. Follow current instructions from _NixOS-WSL_ project to build an system tarball.
  For me this was `nix build github:nix-community/NixOS-WSL#nixosConfigurations.mysystem.config.system.build.installer`
1. Copy the system tarball out
1. Follow the instructions to unregister the old system and import a new one
1. Restore your files and config.
  Fun tip, you can restore system config directly from GitHub or GitLab!

## References

- [WSL sleep disk mount issue](https://github.com/microsoft/WSL/issues/3344)
- [StackOverflow question](https://stackoverflow.com/questions/24966676/transport-endpoint-is-not-connected)
- [NixOS-WSL issue](https://github.com/nix-community/NixOS-WSL/issues/229)

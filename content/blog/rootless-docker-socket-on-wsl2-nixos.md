+++
title = "Rootless Docker socket on WSL2 NixOS"
date = 2023-01-23T17:57:53+10:00
description = "More WSL2 clownery"
[taxonomies]
categories = [ "Technical", "Troubleshooting" ]
tags = [ "wsl", "wsl2", "nixos", "docker", "containers", "docker-engine", "rootless", "security" ]
+++

## Problem

We want to default to rootless Docker when running containers.
When running Docker rootless, each user gets their own socket.
Nix offers then option to automatically set the environment variable required to point to this.
However, out-the-box it points to the wrong location.

> Cannot connect to the Docker daemon at unix:///mnt/wslg/runtime-dir/docker.sock. Is the docker daemon running?

[Just take me to the fix!](#solution)

## Analysis

Let's investigate and see where this might be coming from.

```bash
$ env | grep wslg

SSH_AUTH_SOCK=/mnt/wslg/runtime-dir/yubikey-agent/yubikey-agent.sock
XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
DOCKER_HOST=unix:///mnt/wslg/runtime-dir/docker.sock
PULSE_SERVER=/mnt/wslg/PulseServer
```

Those middle two look interesting.
I'd bet that `DOCKER_HOST` is based on `XDG_RUNTIME_DIR`.
We can confirm that by checking [the source](https://github.com/NixOS/nixpkgs/blob/0b0195ff825259a37c493c200409dcf2d35ed616/nixos/modules/virtualisation/docker-rootless.nix#L67).
Generally, the runtime dir should be writeable, unique per user and for temp stuff like sockets.

```bash
$ stat /mnt/wslg/runtime-dir

  File: /mnt/wslg/runtime-dir
  Size: 360             Blocks: 0          IO Block: 4096   directory
Device: 0,38    Inode: 7           Links: 4
Access: (0700/drwx------)  Uid: ( 1000/   nixos)   Gid: ( 1000/   nixos)
Access: 2023-01-23 09:32:02.425716600 +1000
Modify: 2023-01-23 14:46:27.667379760 +1000
Change: 2023-01-23 14:46:27.667379760 +1000
 Birth: -

$ ls -Al /mnt/wslg/runtime-dir

total 0
drwx------ 3 nixos nixos 60 Jan 23 09:32 dbus-1
drwx------ 2 nixos nixos 80 Jan 23 09:32 pulse
srwxr-xr-x 1 nixos users  0 Jan 23 13:49 vscode-git-493c7fec63.sock
srwxr-xr-x 1 nixos users  0 Jan 23 10:28 vscode-git-910593b70b.sock
srwxr-xr-x 1 nixos users  0 Jan 23 13:43 vscode-git-c88cebb905.sock
srwxr-xr-x 1 nixos users  0 Jan 23 14:46 vscode-git-f4186737d5.sock
srwxr-xr-x 1 nixos users  0 Jan 23 11:03 vscode-ipc-171a1ab1-b7d7-436d-9af1-08e15704abb0.sock
srwxr-xr-x 1 nixos users  0 Jan 23 11:30 vscode-ipc-26352b3a-d6bb-48e1-92b6-694f505da040.sock
srwxr-xr-x 1 nixos users  0 Jan 23 13:43 vscode-ipc-547ac4b7-6dbe-4a37-9342-f66fa81751f7.sock
srwxr-xr-x 1 nixos users  0 Jan 23 14:36 vscode-ipc-604581f9-ca22-45f0-bed6-be424da78e07.sock
srwxr-xr-x 1 nixos users  0 Jan 23 13:43 vscode-ipc-746d2dea-98da-40dc-8509-896bb69df53e.sock
srwxr-xr-x 1 nixos users  0 Jan 23 14:46 vscode-ipc-b3cd2bd7-0df0-4d89-94bc-c44ee9392bbb.sock
srwxr-xr-x 1 nixos users  0 Jan 23 10:28 vscode-ipc-cd8f0e98-cafa-4cde-bec1-a28c095c5436.sock
srwxr-xr-x 1 nixos users  0 Jan 23 13:49 vscode-ipc-fc6a0847-5d5c-47f1-8342-1101235668ad.sock
srwxrwxrwx 1 nixos nixos  0 Jan 23 09:32 wayland-0
-rw-rw---- 1 nixos nixos  0 Jan 23 09:32 wayland-0.lock
```

Ok so it _is_ writable, it's technically going to clash for other users but effectively it's a single-user system.

So we have 2 courses of action really:

- A) Re-point `XDG_RUNTIME_DIR` to the more standard `[/var]/run/user/$(id -u)/`.
- B) Reconfigure the Docker daemon to put its socket in the wslg location.

Let's take a look at each in turn.

### Tracking down XDG_RUNTIME_DIR

While we could set `DOCKER_HOST` again in bashrc, I'd prefer to locate the root of this.
We'll need to understand startup process pretty thoroughly cause if we set it _after_ `DOCKER_HOST` gets set then it won't impact.

Let's see if there's anything logged about it.

```
$ journalctl -r | grep -i xdg

Jan 23 11:07:43 main-laptop systemd[1]: /run/systemd/transient/run-u14.service:22: Unknown key name 'declare -x XDG_RUNTIME_DIR' in section 'Unit', ignoring.
< Repeats a bunch at different times >

$ # Aha, so it's possibly in the bowels of systemd, let's dig in
$ cat /etc/pam.d/systemd-user

# Account management.
account required pam_unix.so

# Authentication management.
auth sufficient pam_unix.so   likeauth try_first_pass
auth required pam_deny.so

# Password management.
password sufficient pam_unix.so nullok sha512

# Session management.
session required pam_env.so conffile=/etc/pam/environment readenv=0
session required pam_unix.so
session required pam_loginuid.so
session optional /nix/store/9rjdvhq7hnzwwhib8na2gmllsrh671xg-systemd-252.1/lib/security/pam_systemd.so

$ grep -i xdg /etc/pam/environment

XDG_CONFIG_DIRS   DEFAULT="@{HOME}/.nix-profile/etc/xdg:/etc/profiles/per-user/@{PAM_USER}/etc/xdg:/nix/var/nix/profiles/default/etc/xdg:/run/current-system/sw/etc/xdg"
XDG_DATA_DIRS   DEFAULT="/nix/store/kr7bhj1z15dpslcwf51pswnf7cvp1wa7-desktops/share:@{HOME}/.nix-profile/share:/etc/profiles/per-user/@{PAM_USER}/share:/nix/var/nix/profiles/default/share:/run/current-system/sw/share"
```

Ok so it's not getting set by PAM's interaction with systemd.
Let's see if there's anything in the user service that manages our sessions.

```bash
$ grep -i xdg  /etc/systemd/system/user@.service.d/overrides.conf`
< Crickets >
$ grep -i xdg /etc/systemd/user.conf
< Tumbleweeds >
$ grep -i xdg ~/.config/environment.d/10-home-manager.conf
< 🏏🏏🏏 >
```

Nope, it's not set by systemd at the level of all-users.
It's *also* not set by my environment drop-ins.

```bash
$ systemctl --user show-environment | grep -i xdg

XDG_CONFIG_DIRS=/home/nixos/.nix-profile/etc/xdg:/etc/profiles/per-user/nixos/etc/xdg:/nix/var/nix/profiles/default/etc/xdg:/run/current-system/sw/etc/xdg
XDG_DATA_DIRS=/home/nixos/.nix-profile/share:/nix/store/kr7bhj1z15dpslcwf51pswnf7cvp1wa7-desktops/share:/home/nixos/.nix-profile/share:/etc/profiles/per-user/nixos/share:/nix/var/nix/profiles/default/share:/run/current-system/sw/share
XDG_RUNTIME_DIR=/run/user/1000
```

Ok now I'm really confused.
So the systemd environment at my user scope has the correct variable??
Maybe we'll have better luck redirecting the socket.

### Setting the socket location

There _should_ to be a reason for WSL to use a different location.
I wonder if it makes more sense to reconfigure Docker to point to this magic wslg directory...
That should's doing a lotta work though.
Other sockets are being created here, so this consolidates them (though fixing the variable might have done same).
Finally, many things assume `[/var]/run/user/$(id -u)/docker.sock`.
Let's investigate the docker daemon config.

```bash
$ systemctl cat docker
# /etc/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/nix/store/p25skbckyar8kpmdxf9fpg423zzs4gpp-moby-20.10.21/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target

# /nix/store/jmkxyvwg6vqz8as4k9qnsdq2kkfcjham-system-units/docker.service.d/overrides.conf
[Unit]
After=network.target docker.socket
Requires=docker.socket

[Service]
Environment="LOCALE_ARCHIVE=/nix/store/sn0l5pwvy1a3l14k0agjp85hwb5qb22k-glibc-locales-2.35-224/lib/locale/locale-archive"
Environment="PATH=/nix/store/0lsabvbq5znilmcrk4xl5jk7rs4mv4c8-kmod-30/bin:/nix/store/h8gvq6r4hgpa71h44dmg9qfx03mj81sv-coreutils-9.1/bin:/nix/store/zml88vnkpm8if114qkbbqd1q7n3ypqqy-findutils-4.9.0/bin:/nix/store>
Environment="TZDIR=/nix/store/11mrj0y0k09j7pzcr78iy5fxgcmzjxq6-tzdata-2022g/share/zoneinfo"



ExecReload=
ExecReload=/nix/store/s0df41v89q42fa3060wls20xhlvg3m7f-procps-3.3.17/bin/kill -s HUP $MAINPID
ExecStart=
ExecStart=/nix/store/ygmyp62pknj6b361k3abnya0050jbavl-docker-20.10.21/bin/dockerd \
  --config-file=/nix/store/zy67kvavwf9yijdn2ih01107s9z8rnzb-daemon.json \


Type=notify
$ # Depends on the socket, let's inspect that.
$ systemctl cat docker.socket
# /etc/systemd/system/docker.socket
[Unit]
Description=Docker Socket for the API

[Socket]
# If /var/run is not implemented as a symlink to /run, you may need to
# specify ListenStream=/var/run/docker.sock instead.
ListenStream=/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target

# /nix/store/jmkxyvwg6vqz8as4k9qnsdq2kkfcjham-system-units/docker.socket.d/overrides.conf
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/run/docker.sock
SocketGroup=docker
SocketMode=0660
SocketUser=root

$ Aha, jackpot...ish. It's the rootful socket location.
$ # Might as well check the config too
$ cat /nix/store/zy67kvavwf9yijdn2ih01107s9z8rnzb-daemon.json

{
  "group": "docker",
  "hosts": [
    "fd://"
  ],
  "live-restore": true,
  "log-driver": "journald"
}

$ # Lets see if we can find same setting in user variant
$ systemctl cat --user docker

# /home/nixos/.config/systemd/user/docker.service
[Unit]
ConditionUser=!root
Description=Docker Application Container Engine (Rootless)
StartLimitInterval=60s

[Service]
Environment="LOCALE_ARCHIVE=/nix/store/sn0l5pwvy1a3l14k0agjp85hwb5qb22k-glibc-locales-2.35-224/lib/locale/locale-archive"
Environment="PATH=/run/wrappers/bin:/nix/store/h8gvq6r4hgpa71h44dmg9qfx03mj81sv-coreutils-9.1/bin:/nix/store/zml88vnkpm8if114qkbbqd1q7n3ypqqy-findutils-4.9.0/bin:/nix/store/bcvccw6y9bfil6xrl5j7psza7hnd16ry-gnug>
Environment="TZDIR=/nix/store/11mrj0y0k09j7pzcr78iy5fxgcmzjxq6-tzdata-2022g/share/zoneinfo"



Delegate=true
ExecReload=/nix/store/s0df41v89q42fa3060wls20xhlvg3m7f-procps-3.3.17/bin/kill -s HUP $MAINPID
ExecStart=/nix/store/kc9bbg5ia603zxjhkql3a3zrxfmfq9m0-docker-20.10.21/bin/dockerd-rootless --config-file=/nix/store/xapq95nh0215l6mj31gysb23ax5wg77z-daemon.json
KillMode=mixed
LimitCORE=infinity
LimitNOFILE=infinity
LimitNPROC=infinity
NotifyAccess=all
Restart=always
RestartSec=2
StartLimitBurst=3
TimeoutSec=0
Type=notify

$ cat /nix/store/xapq95nh0215l6mj31gysb23ax5wg77z-daemon.json

{}

$ # Empty config? Well, maybe we'll find a setting to put in there.
$ systemctl cat --user docker.socket

No files found for docker.socket.
```

Ok so it seems that there's only one location where the socket location is being set, the rootful `docker.socket` unit.
What's odd is there's no user space socket, so we can't adjust the location in the unit file.
[Vendor documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file) doesn't seem to think we can set it in the JSON either.
Nixpkgs [has support](https://search.nixos.org/options?channel=22.11&show=virtualisation.docker.rootless.daemon.settings&from=0&size=100&sort=relevance&type=packages&query=virtualisation.docker.rootless.daemon.settings) for customization though.
We could also symlink the socket but I'm unsure how well that would work across reboots or in general.

## Solution

🤷‍♀️ Stop using WSL 🤷‍♂️

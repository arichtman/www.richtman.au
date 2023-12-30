+++
title = "Rootless Docker on WSL2 NixOS"
date = 2022-11-01T16:11:00Z
description = "Another mousehunt for you to follow"
[taxonomies]
#categories = [ "Technical", "Troubleshooting" ]
tags = [ "wsl2", "nixos", "docker", "containers", "docker-engine", "rootless", "security" ]
+++

## Problem

We want to run containers securely, without messing up the file system, on NixOS, on WSL2.

[Just take me to the fix!](#solution)

## Analysis

So we can set `wsl.docker-native.enable = true` and that'll install the daemon for Docker engine.

```Nix
{
  wsl = {
    docker-native.enable = true;
  };
}
```

```bash
$ docker run --rm -it alpine
docker: Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/create": dial unix /var/run/docker.sock: connect: permission denied.
See 'docker run --help'
```

Ah ok, we're missing permissions to access docker, let's add our user to the `docker` user group.
We'll need to log out and log back in to pick up the group though.

```Nix
{
  wsl = {
    docker-native.enable = true;
  };
  users.users.nixos.extraGroups = [ "docker" ];
}
```

```bash
$ id
uid=1000(nixos) gid=100(users) groups=100(users),1(wheel),131(docker)
$ docker run --rm -it -v "$(pwd):/test" alpine touch /test/foo

$ ls -l ./foo
-rw-r--r-- 1 root root 0 Nov  1 15:17 ./foo
```

Hmmm, this is no good, it's operating as root on the host machine...
Ok let's enable rootless config option, that looks like it'll fix it.

```Nix
{
  wsl = {
    docker-native.enable = true;
  };
  users.users.nixos.extraGroups = [ "docker" ];
  virtualisation.docker.rootless.enable = true;
}
```

```bash
$ sudo nixos-rebuild switch
~ yadda yadda ~
$ docker run --rm -it -v "$(pwd):/test" alpine touch /test/foo

$ ls -l ./foo
-rw-r--r-- 1 root root 0 Nov  1 15:17 ./foo
# Well that's busted, let's bounce the service and see how we go

$ sudo systemctl reload docker

$ sudo systemctl restart docker
# Repeat the test aaaand
```

Hmmm, definitely not fixed.
Let's investigate the service we got here.

```bash
$ sudo systemctl cat docker.service
[Unit]
After=network.target docker.socket
Requires=docker.socket

[Service]
Environment="LOCALE_ARCHIVE=/nix/store/wafdz0spw6033sp66f1frb2rw88bk2pp-glibc-locales-2.34-210/lib/locale/locale-archive"
Environment="PATH=/nix/store/a1hlw5ncs61nfw4vl7wnllgx8jzk8gpb-kmod-29/bin:/nix/store/qarssrazji0q9xp80xg8shsm2crckfr0-coreutils-9.0/bin:/nix/store/j25abvpcbappy74w23l8lfcz7gkrsjhy-finduti>
Environment="TZDIR=/nix/store/1wg88kyiqc21cwcnxb3s1qchjhj339v0-tzdata-2022e/share/zoneinfo"



ExecReload=
ExecReload=/nix/store/nib9862mx2r7s391j7ji0bln6l7582yk-procps-3.3.16/bin/kill -s HUP $MAINPID
ExecStart=
ExecStart=/nix/store/y6bb9ng3z1kqhc5xhz0c596bpdc1sxsw-docker-20.10.18/bin/dockerd \
  --config-file=/nix/store/bjnhgrd0qzwc31sk6n92vnbc7g71z9gv-daemon.json \


Type=notify
$ sudo systemctl cat docker.socket
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

# /nix/store/bzi6nr5n209j38b8x63yzy28kf6wgb9k-system-units/docker.socket.d/overrides.conf
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/run/docker.sock
SocketGroup=docker
SocketMode=0660
SocketUser=root
```

Not much in the service that looks interesting.
But the socket... now that's juicy.
Looks like the config's not getting updated to use a non-root user.
Looking at the [module implementation](https://github.com/NixOS/nixpkgs/blob/1b4722674c315de0e191d0d79790b4eac51570a1/nixos/modules/virtualisation/docker-rootless.nix#L81) it should be very clear when it's rootless.
I bet it's the WSL configuration stiffing us.
Let's drop that and enable the virtualization option.

```Nix
{
  users.users.nixos.extraGroups = [ "docker" ];
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless.enable = true;
}
```

```bash
$ sudo nixos-rebuild switch
starting the following units: systemd-sysctl.service
the following new units were started: docker.socket
warning: the following units failed: docker.service

● docker.service - Docker Application Container Engine
    Loaded: loaded (/etc/systemd/system/docker.service; enabled; vendor preset: enabled)
    Drop-In: /nix/store/wrgd32yiycqc2wd0syiaphjzrmk9h8ir-system-units/docker.service.d
            └─overrides.conf
    Active: activating (auto-restart) (Result: exit-code) since Tue 2022-11-01 15:25:16 UTC; 15ms ago
TriggeredBy: ● docker.socket
      Docs: https://docs.docker.com
    Process: 43455 ExecStart=/nix/store/ip7zg9fr7d2killbif7z78hl8l38pz7n-docker-20.10.18/bin/dockerd --config-file=/nix/store/bjnhgrd0qzwc31sk6n92vnbc7g71z9gv-daemon.json (code=exited, status=1/FAILURE)
  Main PID: 43455 (code=exited, status=1/FAILURE)
        IP: 0B in, 0B out
warning: error(s) occurred while switching to the new configuration
$ sudo systemctl status docker.socket
× docker.socket - Docker Socket for the API
    Loaded: loaded (/etc/systemd/system/docker.socket; enabled; vendor preset: enabled)
    Drop-In: /nix/store/wrgd32yiycqc2wd0syiaphjzrmk9h8ir-system-units/docker.socket.d
            └─overrides.conf
    Active: failed (Result: service-start-limit-hit) since Tue 2022-11-01 15:25:21 UTC; 3min 28s ago
  Triggers: ● docker.service
    Listen: /run/docker.sock (Stream)
            /run/docker.sock (Stream)
        IP: 0B in, 0B out

Nov 01 15:25:14 nixos systemd[1]: Starting Docker Socket for the API...
Nov 01 15:25:14 nixos systemd[1]: Listening on Docker Socket for the API.
Nov 01 15:25:21 nixos systemd[1]: docker.socket: Failed with result 'service-start-limit-hit'.
$ journaltctl -fu docker
Nov 01 15:25:20 nixos dockerd[43594]: failed to start daemon: Error initializing network controller: error obtaining controller instance: unable to add return rule in DOCKER-ISOLATION-STAGE-1 chain:  (iptables failed: iptables --wait -A DOCKER-ISOLATION-STAGE-1 -j RETURN: iptables v1.8.7 (nf_tables):  RULE_APPEND failed (No such file or directory): rule in chain DOCKER-ISOLATION-STAGE-1
Nov 01 15:25:20 nixos dockerd[43594]:  (exit status 4))
Nov 01 15:25:20 nixos systemd[1]: docker.service: Main process exited, code=exited, status=1/FAILURE
Nov 01 15:25:20 nixos systemd[1]: docker.service: Failed with result 'exit-code'.
Nov 01 15:25:20 nixos systemd[1]: Failed to start Docker Application Container Engine.
Nov 01 15:25:21 nixos systemd[1]: docker.service: Scheduled restart job, restart counter is at 3.
Nov 01 15:25:21 nixos systemd[1]: Stopped Docker Application Container Engine.
Nov 01 15:25:21 nixos systemd[1]: docker.service: Start request repeated too quickly.
Nov 01 15:25:21 nixos systemd[1]: docker.service: Failed with result 'exit-code'.
Nov 01 15:25:21 nixos systemd[1]: Failed to start Docker Application Container Engine.
```

Ruh-roh. Looks like The socket had some issues booting.
Returning the wsl configuration statement fixes our `iptables` woes.
Let's check our subuid/guids

```bash
$ grep ^$(whoami): /etc/subuid
nixos:100000:65536
$ grep ^$(whoami): /etc/subgid
nixos:100000:65536
```

Hmm that seems fine. I'll try starting the service myself

```bash
$ systemctl --user start docker
$ systemctl --user status docker
Failed to execute 'pager', using next fallback pager: Permission denied
● docker.service - Docker Application Container Engine (Rootless)
    Loaded: loaded (/etc/systemd/user/docker.service; enabled; vendor preset: enabled)
    Active: active (running) since Tue 2022-11-01 15:41:16 UTC; 1min 48s ago
  Main PID: 44379 (rootlesskit)
    CGroup: /user.slice/user-1000.slice/user@1000.service/app.slice/docker.service
            ├─44379 rootlesskit --net=slirp4netns --mtu=65520 --slirp4netns-sandbox=auto --slirp4netns-seccomp=auto --disable-host-loopback --port-driver=builtin --copy-up=/etc --copy-up>
            ├─44390 /proc/self/exe --net=slirp4netns --mtu=65520 --slirp4netns-sandbox=auto --slirp4netns-seccomp=auto --disable-host-loopback --port-driver=builtin --copy-up=/etc --copy>
            ├─44408 slirp4netns --mtu 65520 -r 3 --disable-host-loopback --enable-sandbox --enable-seccomp 44390 tap0
            ├─44415 dockerd --config-file=/nix/store/yfn9znsklblvqw79jc587af4473pq89j-daemon.json
            └─44443 containerd --config /run/user/1000/docker/containerd/containerd.toml --log-level info

Nov 01 15:41:15 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:15.579684000Z" level=warning msg="Your kernel does not support cgroup blkio throttle.read_iops_device"
Nov 01 15:41:15 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:15.579686700Z" level=warning msg="Your kernel does not support cgroup blkio throttle.write_iops_device"
Nov 01 15:41:15 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:15.579822000Z" level=info msg="Loading containers: start."
Nov 01 15:41:15 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:15.580893400Z" level=info msg="skipping firewalld management for rootless mode"
Nov 01 15:41:16 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:16.053613900Z" level=info msg="Default bridge (docker0) is assigned with an IP address 172.17.0.0/16. Daemon option ->
Nov 01 15:41:16 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:16.295042600Z" level=info msg="Loading containers: done."
Nov 01 15:41:16 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:16.301126900Z" level=info msg="Docker daemon" commit=v20.10.18 graphdriver(s)=fuse-overlayfs version=20.10.18
Nov 01 15:41:16 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:16.301250500Z" level=info msg="Daemon has completed initialization"
Nov 01 15:41:16 nixos systemd[55]: Started Docker Application Container Engine (Rootless).
Nov 01 15:41:16 nixos dockerd-rootless[44415]: time="2022-11-01T15:41:16.751656000Z" level=info msg="API listen on /run/user/1000/docker.sock"
```

Aha... so we _do_ have the capability to run rootless...
Let's try using this instance of the Docker engine by specifying the socket.

```bash
$ DOCKER_HOST=unix:///run/user/1000/docker.sock docker run --rm  -it -v "$(pwd):/test" alpine touch /test/foo
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
213ec9aee27d: Pull complete
Digest: sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad
Status: Downloaded newer image for alpine:latest
$ ls -l foo
-rw-r--r-- 1 nixos users 0 Nov  1 15:45 foo
```

Hrm, now the classical fix would be to enable the rootless service and set the `DOCKER_HOST` variable when logging in.
But this smells funny for NixOS.
Let's add some configuration for setting that socket variable and rebooting.


```Nix
{
  wsl = {
    docker-native.enable = true;
  };
  users.users.nixos.extraGroups = [ "docker" ];
  virtualisation.docker = {
    enable = true;
    rootless.enable = true;
    rootless.setSocketVariable = true;
  };
}
```

```bash
$ env | grep -i docker

$
```

Now that's definitely not behaving right...
I wonder if it's this quote here
> Point DOCKER_HOST to rootless Docker instance for normal users by default.
normal users huh?
> *normal* users
Ohhhhh, NORMAL. USERS.
I swear I saw a config option re normal users...
Aha! Located!
And as a tidy bonus we can clear off the rootful docker service as well as the group membership.

## Solution

```Nix
{
  wsl = {
    # Enables iptables trickery required
    docker-native.enable = true;
  };
  virtualisation.docker = {
    # Installs root
    rootless.enable = true;
    # Sets env var to direct cli to the rootless socket
    rootless.setSocketVariable = true;
  };
  users.users.nixos = {
    # Marks our user for the socket environment variable
    isNormalUser = true;
  };
}
```

```bash
$ sudo nixos-rebuild switch
  ~ snip ~
$ sudo reboot
$ env | grep -i dock
DOCKER_HOST=unix:///run/user/1000/docker.sock
$ docker run --rm -it -v "$(pwd):/test" alpine touch /test/foo

$ ls -l ./foo
-rw-r--r-- 1 nixos users 0 Nov  1 16:06 ./foo
```

## References

- [NixOS configuration.nix rootless option](https://search.nixos.org/options?channel=22.05&show=virtualisation.docker.rootless.enable&from=0&size=50&sort=alpha_asc&type=packages&query=virtualisation.docker)
- [Nixpkgs repo module for Docker](https://github.com/NixOS/nixpkgs/blob/nixos-22.05/nixos/modules/virtualisation/docker-rootless.nix)
- [Rootless Docker documentation](https://docs.docker.com/engine/security/rootless/)
- [Normal user configuration man page](https://www.mankier.com/5/configuration.nix#Options-users.users.%3Cname%3E.isNormalUser)

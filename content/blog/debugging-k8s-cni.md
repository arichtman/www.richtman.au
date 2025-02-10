+++
title = "Debugging a Kubernetes CNI plugin with Containerd"
date = 2025-02-08T14:33:27+10:00
description = "It's hell out there"
[taxonomies]
categories = [ "Technical" ]
tags = [ "kubernetes", "k8s", "networking", "cni", "containers", "linux" , "containerd", "troubleshooting" ]
+++

## Problem

Our CNI is misbehaving.
Pods are either refusing to pull or launch citing sandbox errors,
or they're running and localhost health checks are failing.

## Analysis

The first part of having a CNI is the actual tools.
These are usually binaries, but anything that can be executed should work.
Some tutorials use shell scripts to illustrate the workings.
The tools are typically located somewhere like `/opt/cni/bin/`, but anywhere accessible to the service user will work.
NixOS's `services.virtualisation` option sets this to the Nix store path for `cni-plugins` by default.
If you are planning on using a CNI plugin that is managed by an agent or otherwise out-of-band, you will want to adjust this.

The second part of having a CNI is the container runtime configuration.
The Kubelet doesn't actually access the CNI directly, rather it requests a higher level abstraction from the CRI,
which in turn requests the lower level networking setup via the CNI.
In my case, I'm using `containerd`, which defaults to `/etc/containerd/config.toml`.
Similar to above, the NixOS module rather sets this to point to the Nix store.
They've also deprecated the option to point at a config file, making iteration and inspection more fiddly.

The third and final piece of a CNI is the configuration.
These have their own versioned API spec and presently come in 2 varieties; conf and conflist.
The conflist format allows for multiple CNIs, set in the `plugins` property, whereas plain conf only allows for one.
Note that the config files _must_ have the correct extension in the name, or they will either be read as invalid, or not read at all.
Note also that `.json` is listed as a valid extension. I have not tested this.
They are stored in `/etc/cni/net.d` by default, and the first and _only_ the first located by alphanumeric sorting is used.
You _can_ add more plugins from other files, but `loadOnlyInlinedPlugins` must be `false`, which is default anyways.
Directories named the same as the network will be searched for valid plugin configurations to merge into.

### Common CNI errors

No CNI conf or conflist can be located. Kubernetes says:
`network is not ready: container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized`

A CNI conf was provided but has `conflist` extension. Containerd says:
`failed to reload cni configuration after receiving fs change event(RENAME
\"/etc/cni/net.d/98-loopback.conflist.tmp\")" error="cni config load failed:
failed to load CNI config list file /etc/cni/net.d/98-loopback.conflist: error parsing configuration list:
no 'plugins' key: invalid cni config: failed to load cni config`

The CNI configuration's `type` is incorrect. Kubernetes says:
`Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox
"a7959b6cc667b6518bed7fffbb034b70e93c7abbccfdd6739f76225e523c2667": plugin type="foo" name="lo" failed (add):
failed to find plugin "foo" in path [/opt/cni/bin]`

A plain CNI conf:

```json
{
  "cniVersion": "1.0.0",
  "name": "lo",
  "type": "loopback"
}
```

A multi-plugin conflist:

```json
{
  "cniVersion": "1.0.0",
  "name": "lo",
  "plugins": [
    {
      "type": "loopback"
    }
  ]
}
```

For _containerd_, we can enable detailed logging with `-l/--log-level` when calling the binary.
Debug level turns out to be the sweet spot, trace emits just noise and nothing more detailed about CNI interactions.

```text
level=debug msg="sd notification" notified=true state="READY=1"
level=info msg="containerd successfully booted in 0.089537s"
level=info msg="RunPodSandbox for &PodSandboxMetadata{Name:mytest,Uid:0ee072e9-4f91-43fb-b5dd-7165d1b62ba8,Namespace:default,Attempt:0,}"
level=debug msg="Sandbox config &PodSandboxConfig{Metadata:&PodSandboxMetadata{Name:mytest,Uid:0ee072e9-4f91-43fb-b5dd-7165d1b62ba8,Namespace:default,Attempt:0,},Hostname:mytest,LogDirectory:/var/log/pods/default_mytest_0ee072e9-4f91-43fb-b5dd-7165d1b62ba8,DnsConfig:&DNSConfig{Servers:[127.0.0.53],Searches:[internal],Options:[edns0 trust-ad],},PortMappings:[]*PortMapping{&PortMapping{Protocol:TCP,ContainerPort:80,HostPort:0,HostIp:,},&PortMapping{Protocol:TCP,ContainerPort:8080,HostPort:0,HostIp:,},&PortMapping{Protocol:TCP,ContainerPort:443,HostPort:0,HostIp:,},},Labels:map[string]string{io.kubernetes.pod.name: mytest,io.kubernetes.pod.namespace: default,io.kubernetes.pod.uid: 0ee072e9-4f91-43fb-b5dd-7165d1b62ba8,run: mytest,},Annotations:map[string]string{kubectl.kubernetes.io/last-applied-configuration: {\"apiVersion\":\"v1\",\"kind\":\"Pod\",\"metadata\":{\"annotations\":{},\"labels\":{\"run\":\"mytest\"},\"name\":\"mytest\",\"namespace\":\"default\"},\"spec\":{\"containers\":[{\"image\":\"docker.io/nginx:latest\",\"name\":\"mytest\",\"ports\":[{\"containerPort\":80},{\"containerPort\":8080},{\"containerPort\":443}],\"readinessProbe\":{\"failureThreshold\":99,\"httpGet\":{\"host\":\"::1\",\"path\":\"/\",\"port\":80,\"scheme\":\"HTTP\"},\"periodSeconds\":5,\"successThreshold\":1,\"timeoutSeconds\":3}}],\"dnsPolicy\":\"Default\",\"nodeName\":\"mum.systems.richtman.au\",\"restartPolicy\":\"Always\"}}\n,kubernetes.io/config.seen: 2025-02-09T02:46:09.625756542Z,kubernetes.io/config.source: api,},Linux:&LinuxPodSandboxConfig{CgroupParent:/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-pod0ee072e9_4f91_43fb_b5dd_7165d1b62ba8.slice,SecurityContext:&LinuxSandboxSecurityContext{NamespaceOptions:&NamespaceOption{Network:POD,Pid:CONTAINER,Ipc:POD,TargetId:,UsernsOptions:nil,},SelinuxOptions:nil,RunAsUser:nil,ReadonlyRootfs:false,SupplementalGroups:[],Privileged:false,SeccompProfilePath:,RunAsGroup:nil,Seccomp:&SecurityProfile{ProfileType:RuntimeDefault,LocalhostRef:,},Apparmor:nil,SupplementalGroupsPolicy:Merge,},Sysctls:map[string]string{},Overhead:&LinuxContainerResources{CpuPeriod:0,CpuQuota:0,CpuShares:0,MemoryLimitInBytes:0,OomScoreAdj:0,CpusetCpus:,CpusetMems:,HugepageLimits:[]*HugepageLimit{},Unified:map[string]string{},MemorySwapLimitInBytes:0,},Resources:&LinuxContainerResources{CpuPeriod:100000,CpuQuota:0,CpuShares:2,MemoryLimitInBytes:0,OomScoreAdj:0,CpusetCpus:,CpusetMems:,HugepageLimits:[]*HugepageLimit{},Unified:map[string]string{memory.oom.group: 1,},MemorySwapLimitInBytes:0,},},Windows:nil,}"
level=debug msg="generated id for sandbox name \"mytest_default_0ee072e9-4f91-43fb-b5dd-7165d1b62ba8_0\"" podsandboxid=abd08d33267a2b7b755716f3747c00e929ae80fcd54e04bcde2a63c9e40aceae
level=debug msg="begin cni setup" podsandboxid=abd08d33267a2b7b755716f3747c00e929ae80fcd54e04bcde2a63c9e40aceae
level=debug msg="cni result: {\"Interfaces\":{\"eth0\":{\"IPConfigs\":null,\"Mac\":\"\",\"Sandbox\":\"\",\"PciID\":\"\",\"SocketPath\":\"\"},\"lo\":{\"IPConfigs\":[{\"IP\":\"127.0.0.1\",\"Gateway\":\"\"},{\"IP\":\"::1\",\"Gateway\":\"\"}],\"Mac\":\"00:00:00:00:00:00\",\"Sandbox\":\"/var/run/netns/cni-03f8b925-b7b4-7622-97ed-a81be045d203\",\"PciID\":\"\",\"SocketPath\":\"\"}},\"DNS\":[{},{}],\"Routes\":null}" podsandboxid=abd08d33267a2b7b755716f3747c00e929ae80fcd54e04bcde2a63c9e40aceae
level=error msg="RunPodSandbox for &PodSandboxMetadata{Name:mytest,Uid:0ee072e9-4f91-43fb-b5dd-7165d1b62ba8,Namespace:default,Attempt:0,} failed, error" error="rpc error: code = Unknown desc = failed to setup network for sandbox \"abd08d33267a2b7b755716f3747c00e929ae80fcd54e04bcde2a63c9e40aceae\": failed to find network info for sandbox \"abd08d33267a2b7b755716f3747c00e929ae80fcd54e04bcde2a63c9e40aceae\""
```

Pulling out the CNI result yields the following.
See if you can spot anything (foreshadowing).

```json
{
  "Interfaces": {
    "eth0": {
      "IPConfigs": null,
      "Mac": "",
      "Sandbox": "",
      "PciID": "",
      "SocketPath": ""
    },
    "lo": {
      "IPConfigs": [
        {
          "IP": "127.0.0.1",
          "Gateway": ""
        },
        {
          "IP": "::1",
          "Gateway": ""
        }
      ],
      "Mac": "00: 00: 00: 00: 00: 00",
      "Sandbox": "/var/run/netns/cni-03f8b925-b7b4-7622-97ed-a81be045d203",
      "PciID": "",
      "SocketPath": ""
    }
  },
  "DNS": [
    {},
    {}
  ],
  "Routes": null
}
```

This seems to be returning successfully.
We can make our own dummy CNI that will allow us to dump the commands and environment `containerd` is using on the CNI plugin.
Note that my shebang is for NixOS, you will probably want the usual `#!/bin/bash` or `#!/usr/bin/env bash`
Amend the `type` property on our CNI configuration to `mycni`.

Create `/opt/cni/bin/mycni`, with world read and execute permissions:

```bash
#!/run/current-system/sw/bin/bash
OUT_FILE=/tmp/mycni.log

CMD=$(cat /dev/stdin)
env > $OUT_FILE
echo $CMD >> $OUT_FILE

echo '{
  "cniVersion": "1.1.0",
  "code": 7,
  "msg": "Invalid Configuration",
  "details": "we fucked up"
}'
exit 1
```

Kubelet says:
`network is not ready: container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: Invalid Configuration; we fucked up`

Inspecting the dump it shows that it's running the CNI `STATUS` command.
If we amend our shell script to succeed on `STATUS`, we can get `containerd` running the CNI plugin.

```bash
#!/run/current-system/sw/bin/bash
# Make outputs unique so continual STATUS runs don't overwrite other output
OUT_FILE="/tmp/mycni-${CNI_COMMAND}.log"

INPUT=$(cat /dev/stdin)
env > $OUT_FILE
echo $INPUT >> $OUT_FILE

case $CNI_COMMAND in
  STATUS)
    exit 0
  ;;
  *)
    echo '{
      "cniVersion": "1.1.0",
      "code": 7,
      "msg": "Invalid Configuration",
      "details": "we fucked up"
    }'
    exit 1
  ;;
esac
```

Now kubelet says:
`Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox
"d8a872608ede588d274c91f701a1c597fb16dfbb731e186abca071dc19a8a6a7": plugin type="mycni" failed (add):
Invalid Configuration; we fucked up`

Containerd says:

```text
level=debug msg="begin cni setup" podsandboxid=d8a872608ede588d274c91f701a1c597fb16dfbb731e186abca071dc19a8a6a7
level=error msg="Failed to destroy network for sandbox \"d8a872608ede588d274c91f701a1c597fb16dfbb731e186abca071dc19a8a6a7\"" error="plugin type=\"mycni\" failed (delete): Invalid Configuration; we fucked up"
level=error msg="RunPodSandbox for &PodSandboxMetadata{Name:mytest,Uid:7734ac19-c4eb-4634-8584-f410932db693,Namespace:default,Attempt:0,} failed, error" error="rpc error: code = Unknown desc = failed to setup network for sandbox \"d8a872608ede588d274c91f701a1c597fb16dfbb731e186abca071dc19a8a6a7\": plugin type=\"mycni\" failed (add): Invalid Configuration; we fucked up"
```

Bingo, we can inspect our precise CNI plugin runtime call.

`grep -e ^CNI_ /tmp/mycni-ADD.log ; tail -1 /tmp/mycni-ADD.log`:

```text
CNI_CONTAINERID=172fd1770bccf2e7afabb7d54af6f319485de15ec1c704504cbfdc7e2082d778
CNI_IFNAME=eth0
CNI_NETNS=/var/run/netns/cni-4b829192-50bf-bd56-f9de-44f5f07c507b
CNI_COMMAND=ADD
CNI_PATH=/opt/cni/bin
CNI_ARGS=IgnoreUnknown=1;K8S_POD_NAMESPACE=default;K8S_POD_NAME=mytest;K8S_POD_INFRA_CONTAINER_ID=172fd1770bccf2e7afabb7d54af6f319485de15ec1c704504cbfdc7e2082d778;K8S_POD_UID=4534d3d9-9c33-416b-953e-4a695c7009d4
{"cniVersion":"1.1.0","dns":{"nameservers":["9.9.9.9"]},"name":"my-cni","type":"mycni"}
```

We can now create a test harness to run our actual CNI, which we can then trace and examine more directly.

test-add.sh:

```bash
#!/run/current-system/sw/bin/bash

echo '{"cniVersion":"1.1.0","dns":{"nameservers":["9.9.9.9"]},"name":"my-cni","type":"loopback"}' | \
CNI_CONTAINERID=172fd1770bccf2e7afabb7d54af6f319485de15ec1c704504cbfdc7e2082d778 \
CNI_IFNAME=eth0 \
CNI_NETNS=/var/run/netns/cni-4b829192-50bf-bd56-f9de-44f5f07c507b \
CNI_COMMAND=ADD \
CNI_PATH=/opt/cni/bin \
CNI_ARGS="IgnoreUnknown=1;K8S_POD_NAMESPACE=default;K8S_POD_NAME=mytest;K8S_POD_INFRA_CONTAINER_ID=172fd1770bccf2e7afabb7d54af6f319485de15ec1c704504cbfdc7e2082d778;K8S_POD_UID=4534d3d9-9c33-416b-953e-4a695c7009d4" \
  /opt/cni/bin/loopback
```

Running our harness yields:

```json
{
  "code": 999,
  "msg": "failed to Statfs \"/var/run/netns/cni-4b829192-50bf-bd56-f9de-44f5f07c507b\": no such file or directory"
}
```

Since we didn't get this during normal operation, it does seem like the network namespace _is_ being created.
The CNI plugin seems to be expecting a network namespace, and is provided with the path for one.
Let's try normal operation using `containerd` but with `ip netns monitor` running.

```text
add cni-a33f2365-63e4-5363-a1e1-99219c682963
delete cni-a33f2365-63e4-5363-a1e1-99219c682963
```

So the CNI _is_ successfully creating network namespaces.
Is something removing them I wonder...
Checking `NetworkManager` journals and `dmesg` yields nothing close in time, just some IPv6 errors.

Let's see about running a container using the CRI, but bypassing `containerd`.
`runc` directly doesn't allow us CNI interaction, but `ctr` does!
We'll use the `--rm` flag to conveniently clean up as we go.

```bash
ctr image pull registry.k8s.io/pause:3.10
ctr run --rm --cni registry.k8s.io/pause:3.10 mycontainer
```

Monitoring the network namespaces doesn't show any changes though.
So this might not be calling the CNI plugin at all, or incorrectly?
It is pausing, but a quick check for entrypoint override revealed no shells to use.
So let's try pulling something we can prove is running, not just hanging.

```bash
# This fails, presumably due to the redirect/aliasing happening
# The error message is misleading though, being unauthorized rather than not found or redirected but not following.
ctr image pull docker.io/alpine:3.21
ctr image pull docker.io/library/alpine:3.21
ctr run --rm --cni docker.io/library/alpine:3.21 mycontainer
id
# uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
pwd
# /
```

The container is indeed running and accessible, but no network namespace changes.
It's possible to bind it to various namespaces with `--set-ns`, but those are supposed to be existing.
Which our CNI plugin is creating successfully but losing instantly.
Let's swap back to our dummy CNI and see if it's being invoked to delete.
Yes, it is being invoked to delete. _BUT_, our netns monitor shows the namespace created and deleted.
So `containerd` must be creating and deleting the namespace, because our debug plugin never touches namespaces or interfaces.
Which means the CNI plugin's responsibility _excludes_ namespace creation.

Looks like CNI plugins have a debug plugin anyhow, but they don't compile any plugins for their releases.

```bash
git clone https://github.com/containernetworking/cni.git && cd cni
cd plugins/debug
# Need to statically link it cause NixOS. You may not need this.
CGO_ENABLED=0 go build
./debug
```

With this in place we can add a CNI configuration for it.

```json
{
  "cniVersion": "1.1.0",
  "name": "my-cni",
  "plugins": [
    {
      "type": "debug",
      "cniOutput": "/tmp/cni-output.txt"
    }
  ]
}
```

This yields:

```text
CmdAdd
ContainerID: 3886f52232a93bccfcd5fd4d5d90be55b0f772daa1980691b69ec7f191085424
Netns: /var/run/netns/cni-da58728d-034e-fe07-85dc-9ea213d09918
IfName: eth0
Args: K8S_POD_NAMESPACE=default;K8S_POD_NAME=mytest;K8S_POD_INFRA_CONTAINER_ID=3886f52232a93bccfcd5fd4d5d90be55b0f772daa1980691b69ec7f191085424;K8S_POD_UID=ababcbdf-e408-475e-847e-f5aa3578b3c8;IgnoreUnknown=1
Path: /opt/cni/bin
StdinData: {"cniOutput":"/tmp/cni-output.txt","cniVersion":"1.1.0","name":"my-cni","type":"debug"}
----------------------
CmdDel
ContainerID: 3886f52232a93bccfcd5fd4d5d90be55b0f772daa1980691b69ec7f191085424
Netns: /var/run/netns/cni-da58728d-034e-fe07-85dc-9ea213d09918
IfName: eth0
Args: IgnoreUnknown=1;K8S_POD_NAMESPACE=default;K8S_POD_NAME=mytest;K8S_POD_INFRA_CONTAINER_ID=3886f52232a93bccfcd5fd4d5d90be55b0f772daa1980691b69ec7f191085424;K8S_POD_UID=ababcbdf-e408-475e-847e-f5aa3578b3c8
Path: /opt/cni/bin
StdinData: {"cniOutput":"/tmp/cni-output.txt","cniVersion":"1.1.0","name":"my-cni","prevResult":{"cniVersion":"1.1.0"},"type":"debug"
```

## Solution

Plumbing the `containerd` source code for the error we find the source of the message.
It's [checking the CNI plugin result for IPs](https://github.com/containerd/containerd/blob/59c8cf6ea5f4175ad512914dd5ce554942bf144f/internal/cri/server/sandbox_run.go#L409)
on the [default interface name](https://github.com/containerd/containerd/blob/59c8cf6ea5f4175ad512914dd5ce554942bf144f/internal/cri/server/helpers.go#L68).

It's said that all network namespaces automatically get loopback as a Linux thing, so you'd think perhaps just letting it go naturally might work.
Removing all CNI configurations causes `containerd` to warn that it has no configuration, and the Kubelet `STATUS` calls fail also.
Let's add some simple CNI config that'll put IPs on `eth0`.
Turns out, we don't even need the loopback as it seems to get implicitly added with the network namespace anyway.
I think it's actually a Linux thing.

```json
{
  "cniVersion": "1.1.0",
  "name": "my-cni",
  "plugins": [
    {
      "type": "ptp",
      "ipam": {
        "type": "host-local",
        "subnet": "10.1.1.0/24"
      },
      "dns": {
        "nameservers": ["9.9.9.9"]
      }
    }
  ]
}
```

```bash
# Check host network interfaces, verify vEth has been created
ifconfig
# Verify network namespaces, grab pid
lsns
# Check what's listening in this namespace
nsenter -t 50715 -n ss -tulpn
# Check nginx service on loopback
nsenter -t 50715 -n curl localhost
# View network interfaces in the namespace, note the IP on the vEth pair
nsenter -t 50715 -n ifconfig
# Now with that IP, test the nginx service from the host network namespace
curl http://10.1.1.9
```

With this we can see that:

- The CNI plugin is running successfully
- A vEth pair is being created
- Our `nginx` service is listening on port 80
- Host routing to the vEth interface is working

The container is now pulling image and running!
Health checks are still failing though.
For this we need to loosen the kernel's _reverse path filtering_.

Turns out the kernel can be configured to reject packets that would return via a different network interface.
In our case, I believe the Kubelet is sending the health checks, which would originate with the host netns default interface IP.
This would be IP forwarded or otherwise land on the vEth interface, which is in a different subnet, causing the return routing to not match.
It may also be in the pod netns where the reverse pathing doesn't quite line up, I am out of energy to dig further into it.
At any rate, setting `net.ipv{4,6}.conf.{all,default,$interface}.rp_filter` to off (`0`) or loose (`2`) seemed to fix the health checks.

## References

- [CNI specification](https://www.cni.dev/docs/spec/)
- [Kubernetes network plugins documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [Containerd CRI configuration docs](https://github.com/containerd/containerd/blob/main/docs/cri/config.md)
- Filip Nikolic's excellent _Demystifying_ talks and repos;
  [CNI](https://github.com/f1ko/demystifying-cni)
  [CRI](https://github.com/f1ko/demystifying-cri)
- [Eran Yanay's CNI from scratch](https://github.com/eranyanay/cni-from-scratch)
- [Antonio's Istio->Cilium post](https://blog.goorzhel.com/istio-to-cilium-a-grand-yak-shave/)

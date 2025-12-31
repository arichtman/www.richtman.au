+++
title = "Container Security"
description = "Summary of the book"
[taxonomies]
categories = [ "Personal", "Meta" ]
tags = [ "reference", "book", "professional-development", "summary", "docker", "containers" ]
+++

# Container Security

Personal note:
I'll only be jotting down things that are new, profound, or crucial.

## Container Security Threats

All the usual ground-level stuff.

## Linux System Calls, Permissions, and Capabilities

Can prevent sticky bit/setuid escalation with `--security-opt no-new-privileges` but this can fall over if host paths are mounted as volumes.

`man capabilities`

- `CAP_NET_BIND_SERVICE` low-number port binding
- `CAP_SYS_BOOT` restart
- `CAP_SYS_MODULE` kernel module modification
- `CAP_BPF` eBPF modification

See capabilities of an file: `getcap $(which ping)`

See capabilities of a process: `getpcaps $(pgrep ping)`

## Control Groups

Main progression of cgroups v2 is a single unified hierarchy for managing all the supported resource types
rather than having separate hierarchies for the different types of resource being managed.

`cat /sys/fs/cgroup/cgroup.controllers >> cgroup.subtree_control`

Directories under `cgroup` are cgroups.
`cat cgroup.procs` to see processes.
Every process member of exactly one cgroup.

`pgrep sleep >> /sys/fs/cgroup/$(whoami)/cgroup.procs` moves process to cgroup.
Confirm with `cat /proc/$(pgrep sleep)/cgroup`.

Different drivers available for cgroups but Systemd very common.
`system.slice` directory is part of how Systemd manages this.
`/sys/fs/cgroup/system.slice/docker-$CONTAINER_ID.scope/...`

`/sys/fs/cgroup/$(whoami)/pids.max` or `--pids-limit`.
`echo 1 > /sys/fs/cgroup/$(whoami)/cgroup.kill`

## Container Isolation

Cgroups control resources that processes can use, namespaces control what they can see.
Process is in exactly one namespace of each type.

Namespaces:

- UTS: hosts and domain names
- Process IDs
- Mounts
- Network
- User and group IDs
- IPC
- Cgroups
- Time

Need to `sudo lsns` to see everything.
`unshare` allows process child/fork to change namespaces.
You probably need `--fork` when using `sudo unshare` for it to work.
`ps` reads `/proc` directly, so even `unshare`ing the PID namespace doesn't impact visibility of system processes.
<!-- Seems whack, I'm not sure what use the PID namespace feature is then -->

`pivot_root` should be preferred over `chroot`, since it uses mount namespaces to prevent access to the original/"real" file root path.

Poor man's container: `sudo unshare --pid --fork --mount-proc --mount chroot $UNPACKED_CONTAINER_PATH sh`

Proc mounts and any other mounts made won't get cleaned up on process exit, and require manual cleanup.

Network namespaces always come with loopback.
<!-- Aha! This I learned the hard way with Cilium CNI assuming such -->

Add a vEth peer:
`sudo ip link add ve1 netns 28586 type veth peer name ve2 netns 1` then
`sudo ip link set ve2 up`

User namespaces get numeric ID mappings, `/proc/$(pgrep sleep)/uid_map`.
Group IDs the same pattern.

- Lowest ID in child to start mapping at
- Lowest ID in host to start mapping at
- Range to map (total count)

IPC namespaces: `ipcs; ipcmk -M 1000; ipcs`

Cgroup namespaces suffer from the same host-view-needs-remount issue that process namespaces do.
`mount -t cgroup2 none $UNPACKED_CONTAINER_PATH/sys/fs/cgroup`

Time namespaces are useful for debugging kernel and application issues, but are not used in practice with containers.
Practically, coordinating time and corellating things across containers would be a pain.
Security-wise, attackers could obfuscate their activities or trigger vulns by messing with time.

Pods vs Containers:
Common network (duh) and IPC (sockets, memory comms) namespaces, optional shared process namespace for signals.

## Virtual Machines

Kernel - ring 0, User Space - ring 3.

_VMM_: Virtual Machine Manager. Sometimes used to refer to the user-facing tool, rather than the actual component that manages virtualization.
Type 1 VMMs are hypervisors (Xen, ESX[i], Hyper-V), and run bare metal, no OS, and in ring 0. Guest OS kernels run in ring 1.
Type 2 VMMs are hosted (QEMU, Parallels, VirtualBox).
Kernel-based VMMs (KVM) blur the line, considered Type 1 because the guest OS doesn’t have to traverse the host OS, but it's nuanced.

Privileged calls, when attempted outside of ring 0, get _trapped_.
_Trapped_ calls trigger _handlers_.
In addition to priv calls, there's also _sensitive_ calls, which are CPU instructions that impact resources.
The VMM needs to handle these instructions on behalf of the guest OS, because only the VMM has a true view of the machine’s resources.
There is also another class of sensitive instructions that behaves differently when executed in Ring 0 or in lower-privileged rings.
Again, a VMM needs to do something about these instructions because the guest OS code was written assuming the Ring 0 behavior.

Not all _sensitive_ instructions are _privileged_, so tough to handle universally.
Sensitive but unpriv is called _non-virtualizable_.

Handling non-virtualizable calls:

- _Binary translation_: All the nonprivileged, sensitive instructions in the guest OS are spotted and rewritten by the VMM in real time.
  This is complex, and newer x86 processors support hardware-assisted virtualization to simplify binary translation.
- _Paravirtualization_: guest OS is rewritten to avoid the non-virtualizable set of instructions, effectively making system calls to the hypervisor.
  Xen does this.
- _Hardware virtualization_: allows hypervisors to run in a new, extraprivileged level known as VMX root mode, which is essentially Ring –1.
  This allows the VM guest OS kernels to run at Ring 0 (or VMX non-root mode), as they would if they were the host OS.
  Intel VT-x does this.

Sharing a kernel is always a risk, and hypervisors have a much simpler job/smaller attack surface/less complexity since VMs are never expected to share memory or kernels.

## Container Images

`index.json` points to the _manifest_ in `blobs/`.
Images need to be unpacked into _filesystem bundles_, `umoci unpack --image $IMAGE_URI .`.
This yields (among others) `rootfs/` and `config.json`, config.json being an OCI-compliant thing.

Secure build options:

- BuildKit `docker-container` driver
- Rootless daemon
- Podman/buildah
- Bazel
- Nix (ehe)
- Language-specific tooling e.g. Go - ko, Java - jib

Multiplatform images work by serving a _manifest_ that points to several architectures.
Different architecture images all need to be scanned and hardened, you can't count handling one to be sufficient for the other.
Image _digests_ are hashes of their _manifest_, and will change if any of the blob hashes change.

## Supply Chain Security

Post-build SBOM generation leans on discovery, and is generally poorer than combining language-specific generators with container-based ones.

Minimizing images:

- Scratch
- Distroless or Minimal
- Slim using Chisel or Slim Toolkit

Docker Content Trust is based on Notary project v2, and has major cloud player support.
Competitor is Google's Sigstore project, which is the Kubernetes de facto.
Sigstore uses OIDC for keyless signing.
<!-- I mean there's still keys/certs. I bet I could manage this with Step-CA too... -->

Sigstore components:

- `cosign`: signs and verifies
- `fulcio`: short-lived certs
- `rekor`: immutable ledger of signature events

## Software Vulnerabilities in Images

FedRAMP says high-to-medium risk - controls within 30 days.
CISA says critical - remediation within 15 days.

## Infrastructures as Code and GitOps

GitOps reduces focus on the cluster/infra itself, but shifts it to source control access.

Recommendations:

- All commits signed enforced
- Release tags signed
- Branch protections
- No force push
- MFA git credentials
- Short life credentials for CI/CD (OIDC)
- Block merge on scans
- Last-priv repo access
- Possibly separate manifests from application repo <!-- I have thoughts about this -->
- Audit logging
- Admission controllers and runtime security

## Strengthening Container Isolation

_Sandboxing_: limiting a process's access to resources/actions that could impact anything else.

### Seccomp

Secure Computing Mode - very limited syscalls == limited utility.
Superseded by _seccomp-bpf_.

Profiles indicate what to do when a packet matches a filter.
Container-wise, only two options - allow or deny - making it a blocklist of sorts.
Docker has a default seccomp profile that's a good choice, lets most things work still.
Ideally, custom profiles per-app.

Approaches to making custom profiles:

- `strace`
- Security Profiles Operator
- Commercial tools

Since syscalls change all the time, new kernel versions require testing and adjustment.

### AppArmor

Linux security module.
Profiles can be bound to executables.

_Mandatory Access Controls_ (MAC): controlled by central admin with zero chance for users to modify or pass.

Linux file permissions are _Discretionary Access Controls_ (DAC), can be modified by users.

Check with `/sys/kernel/security/lsm`.
Profiles under `/etc/apparmor.d/`, use `apparmor_parser`to load, check with either `/sys/kernel/security/apparmor/profiles` or `apparmor_status`.

`docker run --security-opt="apparmor:<profile name>"`, `docker inspect | grep AppArmorProfile`.

### SELinux

Security-Enhanced Linux.
Operates based on _contexts_, _domains_, and _labels_ - including file access.
Key point: *both* DAC *and* SELinux must allow for an action to take place.
Can be very involved to create a profile - best left to developers.

`ls -lZ` and `ps -Z`
Docker volumes need either `:z` or `:Z` to auto-set labels allowing access.

### gVisor

Intercepts syscalls and implements paravirtualization.
_Sentry_ component intercepts and is heavily seccomp sandboxed, actual syscalls offloaded to _Gofer_ component.
Works like a guest kernel in userspace, since it reimplements many syscalls.
gVisor protection works both ways, with host having less visibility into processes _inside_ the container.
Perf takes a hit and may need tuning, though there is a KVM-mode for bare metal deployments.

### Kata Containers

Containers in micro-VMMs.

### Lightweight VMs/Micro VMs

Examples: Firecracker, Cloud Hypervisor, Edera.

Most perf gains come from removing device enumeration and device support.

- Firecracker originated in AWS and is used at scale for running Lambda work‐loads.
  It is designed to provide the minimal necessary functionality for running and isolating container workloads with the fastest startup times.
- Cloud Hypervisor supports more complex workloads such as nested virtualization, Windows as a guest OS, and GPU support.
- Edera takes the approach of running containers in lightweight VM-like "zones",
  with an emphasis on security based on stronger isolation than conventional containers.
- Apple Containerization allows containers to run in their own lightweight VMs on a Mac,
  without requiring a Linux virtual machine to act as the host for those containers.

All of these preclude normal use of eBPF, and limit it's utility.

### Unikernels

Examples: IBM Nabla, Unikraft.

Strip everything out of the kernel except what the application needs.
Requires per-application builds but boots natively on hypervisors.

## Breaking Container Isolation

Containers default to running as root.
Configure your runtimes etc to at least to u/gid mapping.

If you muck with `process.user.uid` in `config.json` you can adjust the user.

Sticky bit usually works, unless the app developers have specifically written something to handle it and shed the file owner on the process.

Some apps still demand root, e.g. Nginx cause of port binding, or for installing software.
Docker now defaults to allowing unprivileged port binding to all with `net.ipv4.ip_unprivileged_port_start=0`.

Kernel modules are less safe, need `CAP_SYS_MODULE`, eBPF preferred, need `CAP_BPF` at least, plus others depending on what BPF program is doing.

Rootless container support still coming along, Alpha in kubernetes and some things like capabilities behave differently due to user namespace.
Another example is `CAP_NET_BIND_SERVICE` for low port numbers - won't work on host even if granted to rootless container.
Also FS must support user id remapping.

Docker defaults to a subset of root capabilities, `--privileged` immediately grants all.
`libpcap`'s `capsh` tool can show current caps.
`libbpf-tools`'s `capable` tool can show cap events, allowing you to build a tailored set.

Gotcha: volume mounts _within_ a `readOnly` volume mount can be writeable, use `recursiveReadOnly`.

Docker with `--pid=host` is a bad idea since it shares way too much with the container i.e. it can see and send signals to other containerized processes.

## Container Network Security

_Microsegmentation_: where network policies are defined in terms of workloads and services rather than between individual containers.

Weirdly, K8s _NetworkPolicy_ is native, but CNIs are not required to implement.

_netfilter_ is the underlying engine, `iptables` is the legacy tool to configure them.

 IPVS, which was more performant for kube-proxy’s case. But IPVS never really took off for a number of reasons:
it requires ip_vs kernel modules (which can be brittle),
it wasn’t adopted by public cloud providers, and the ecosystem of tooling that many operators grew familiar with around iptables didn’t work with it.
nftables is another more modern approach, and there is a project to use it for a more performant version of kube-proxy.
But the Kubernetes community has already moved on to eBPF-based solutions.

Cilum-cli stuff:

- `cilium-dbg bpf lb list`
- `cilium-dbg identity list`
- `cilium-dbg bpf policy get $ID`

If using sidecars for service mesh, ensure `CAP_NET_ADMIN` etc is not made available to the application container, lest it try to circumvent the proxy sidecar.

## Securely Connecting Components

Netscape never published SSLv1 cause it was shit.
SSLv3 became (mostly) TLSv1.0.

Wireguard isn't FIPS-compliant just cause it's a beaurocratic headache.
WolfSSL swaps out the crypto suite with FIPS-compliant bits.

IPsec works on existing interfaces, rather than dedicated ones like Wireguard.
IPsec has two modes, tunnel and transport.
Tunnel mode is considered more secure because it encrypts the IP header for the original packet,
which includes the source and destination IP addresses, and it can be used where the packets will traverse NAT devices.
Transport mode generally has better performance, and it’s perfectly suitable in a private network where the IP addresses are not considered sensitive.

Just enrypting traffic between hosts/nodes using their own identity may be sufficient for security.

## Passing Secrets to Containers

Environment variables, even set at runtime, are not ideal:

- Visible unecessarily on inspecting the resource
- Often dumped by processes/logging
- Can be inspected from the host under the `/proc` directory.
- Can't be updated once running (though I think updating while running isn't so straightforward, even with files).

Secret store CSI driver is good, but a lot of the native ways of consuming secrets rely on k8s secret resources, so you lose some of the advantages of the other either way.
Apparently Kubernetes now has a native encryption option for secrets which is customizable, but most people go with what their cloud provider offers.

Even `tmpfs`-mounted secrets are accessible to root user, so as always, mind yer roots.

## Container Runtime Protection

Broad-strokes approaches:

- Image runtime policies
- Network traffic restrictions
- Limiting executables
- File access controls
- Users and groups

### Technology Options for Runtime Security

`LD_PRELOAD` can be used to forcibly override system libraries with instrumented or limited ones.
Doesn't work on statically linked binaries, can be worked around, difficult to make one-size-fits-all with different library versions like `musl`.

`ptrace` can be used to track a process.
Has huge overhead, is easily detected by the traced process, requires `CAP_SYS_PTRACE` which opens other holes, typically crippled for this use case by default on many distros.
Practically - unworkable.

Seccomp, AppArmor, SELinux: more static in nature, crude policies in some, abstractions make it difficult to express Kubernetes concepts.
Limited observability - crude logging with no Kubernetes information.
Cannot help with a malicious program that remains within policy.

Kernel-based is a great option vantage-point-wise and lifecycle-wise.
Kernel modules though are brittle and fail poorly.

eBPF - no surprise she likes it.
`libbpf-tools`'s `execsnoop`.

### Container Runtime Security Tools

- Falco (the big one)
- Tetragon
- Tracee
- Inspektor Gadget
- Commercial options

Falco has no enforcment options in-kernel, best you can do are user-space tools which is effectively just kill the container.
Falco has paid options for enterprise.

Tetragon includes an agent for exporting to SEIM, and uses in-kernel filtering to keep the data from being noisy.
Can use the Linux Security Module (LSM) API (same as AppArmor) but in conjunction with eBPF to do complex dynamic policies.
Enforcement has options, including; report, override, kill.
In-kernel enforcement means the syscall never completes before the SIGKILL is sent.
Has Prom metrics.
Tetragon has paid options for enterprise.

Tracee is AquaSec, and also detection but no enforcement.
_Does_ do in-kernel filtering, but kludgily.

Inspektor Gadget is a collection of gadgets not a solution, so neither detection nor enforcement.
Useful for; execution monitoring, capabilities monitoring, network tracing, syscall tracing, file access auditing.

Prevention vs Alerting is a balance. Too lax and you're too late, too tight and you're in self-inflicted pain with Kubernetes fighting your tool killing the pod.
You may wish to quarantine a container for later investigation, `docker pause` can do this but Kubernetes has no such concept.
For Kubernetes though you could isolate it using a focussed NetPol, cordon/taint the node to preserve it's state, and use the kubelet checkpoint API to capture state.

eBPF changes can roll out live, so policy changes and evolution can move fast.

## Containers and OWASP Top 10

### Broken Access Control

- Don’t run containers as root.
- Limit the capabilities granted to each container.
- In Kubernetes, use RBAC to limit permissions.
- Use rootless containers, if possible.

### Cryptographic Failures

- Encrypt both at rest and in-transit
- Mind your ciphers and algorithms
- Least priv on accessing decryption keys
- Maybe secrets scanning

### Injection

This is up to the application, no specific container mitigations (though I would consider WAF in service mesh maybe).

### Insecure Design

Microservices allows breaking down threat models to bite-size pieces, Kubernetes allows platform-level approaches.

### Security Misconfiguration

- Benchmarks like CIS
- Cloud Security Posture Management (CPSM).
  OSS options include; Cloud Custodian, Prowler, CloudSploit.
  Vendor options as well.
- Env vars only for non-sensitive data
- Private container registry with secured access
- NetPol

### Vulnerable and Outdated Components

Image scanners, with capabilities of; rebuilding container images with up-to-date packages, identify running vulnerable containers and replace.

### Identification and Authentication Failure

Standard advice for application-level implementation.
Credentials that the apps _themselves_ use treated as secrets.
Consider offloading authentication to service mesh.

### Software and Data Integrity Failures

This includes supply chain security failures.
Signing images, verifying containers, and securing CI/CD.

Data integrity includes deserialization bugs, which are not affected by containerization.

### Security Logging and Monitoring Failures

IBM report _Cost of Data Breaches_ (2025) reckons average 181 days to identify breach, further 60 for containment.

Centralized logging including:

- Container start/stop, image identity, user that launched
- Access to secrets
- Modification of privileges
- Modification of container payload
- Inbound and outbound network connections
- Volume mounts
- Failed actions

### Server-Side Request Forgery

Container-wise, she thinks this would be higher as you could convince an application to hit the cloud provider's metadata API or the control plane.
Limit these services' access to only trusted workloads.

## Conclusions

This wasn't really a conclusions section, nor a summary.
Just kindof a little end cap.

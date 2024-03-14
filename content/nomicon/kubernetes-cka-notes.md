+++
title = "Kubernetes"
description = "Personal notes"
[taxonomies]
categories = [ "Technical" ]
tags = [ "cloud", "k8s", "kubernetes", "containers" ]
+++

# Kubernetes

CKA notes

Stuff to work on:

- NetworkPolicy - practice writing manifests, allow and deny
- Ingress `rewrite-target` & cross-namespace shared ingress via pathing
- System-level stuff (logs, services, kubeconfig files, config files, linux networking)
- RBAC (auth modes, apiGroups, non resource URLs)
- CNI (spec, isntallation, config, pod ip range vs service cluster ip range)
- DownwardAPI
- EnvFrom and secret volumeMounts
- Security contexts
- Taints/Tolerations - running stuff on control plane
- Node affinity - podAffinity, topologies, topologyKey
- TopologySpreadConstraints
- Nano use - selecting, deleting lines, yank, copy-cut-paste
- Custom schedulers?
- Volume types, claims, and binding - making and using a PV and PVC, emptyDir, HostPath
- etcd administration (backup vs snapshot, api versions, wal vs member vs whatever)
- Cluster-managed certificates, signing requests etc
- kubeadm cluster administration and upgrade

Container runtimes

- Containerd is _just_ the runtime daemon bit of the whole Docker setup
- `ctr` is the unsupported cli tool for containerd
- `nerdctl` is the community-supported, Docker-cli-like tool for Containerd
- `crictl` is the cli tool that most closely follows what k8s is doing
- Since Containerd implements the CRI, `crictl` can be used on it.
- `crictl` will work across multiple implementations of CRI

System stuff

- `/etc/kubernetes/manifests` contains stuff for the kubelet to run
- `/var/log/pods` and `/var/log/containers` for log files
- `/var/lib/kubelet` and such for config files
- `kubeadm upgrade plan`
- `kubeadm token create --print-join-command`
- `apt show $package -a | grep $version`
- `apt install --only-upgrade $package=$version`
- `apt install kubectl=$version-00 kubelet=$version-00`
- `ETCDCTL_API=3 etcdctl snapshot $out_path`
- `ip route; ip link; ip a`
- `netstat -anp`
- CNI default in `/opt/cni/bin`, config in `/etc/cni/net.d`

Kubectl

- `run $podName --image $imageURI --port $containerPort --expose --command $bin -- $args` (--expose creates a service)
- `expose`
- `create configmap --from-literal key=value --from-literal foo=bar`
- `create cm -f cm.yaml`
- `set env po/pod1 TREE1 --from cm/trauerweide --keys tree`
- `expose deploy --name europe --port 80 --target-port 80 --type ClusterIP --selector app=europe`
- `create ingress world --class nginx --rule="world.universe.mine/europe/*=europe:80" --rule="world.universe.mine/asia/*=asia:80"`
- `create sa $UNIQUE_NAME --clusterrole $CROLE --serviceaccount $NAMESPACE:$NAME`
- `auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<serviceaccountname> [-n <namespace>]`
- `create clusterrolebinding --clusterrole view --serviceaccount ns1:pipeline --serviceaccount ns2:pipeline`
- `create role --verb create --verb delete --resource deployments`
- `create rolebinding --role pipeline --serviceaccount ns1:pipeline pipeline`
- `get ns --no-headers -o custom-columns='N:.metadata.name,V:.metadata.resourceVersion'`
- `get events -A --sort-by='{.metadata.creationTimestamp}'`
- `taint no control-plane node-role.kubernetes.io/control-plane=:NoSchedule`
- `patch no/node01 -p '{ "metadata": { "labels" : { "color" : "blue"}} }'`
- `label po/whatever key=value foo=bar`
- `top po --sort-by=memory|cpu`

Labs

```shell
alias k=kubectl
alias j='journalctl -xe'
alias s=systemctl
alias kns='kubectl config set-context --current --namespace'
export EDITOR=nano
export KUBE_EDITOR=nano # it's all KodeKloud comes with!
echo 'set tabsize 2
set tabstospaces' >> ~/.nanorc
source <(kubectl competion bash)
```

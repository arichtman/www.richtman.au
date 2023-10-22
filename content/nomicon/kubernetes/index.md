+++
title = "Kubernetes"
description = "Personal notes"
date = 1970-01-01
[taxonomies]
categories = [ "Technical" ]
tags = [ "cloud", "k8s", "kubernetes", "containers" ]
+++

# Kubernetes

CKA notes

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

KillerKoda

```shell
alias k=kubectl
alias j='journalctl -xe'
alias s=systemctl
alias kns='kubectl config set-context --current --namespace'
sudo add-apt-repository -y ppa:maveonair/helix-editor
sudo apt update
sudo apt install -y helix
export EDITOR=hx
```

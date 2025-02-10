+++
title = "Kubernetes Intermediate Cheat Sheet"
date = 2025-02-11T08:50:21+10:00
description = "Swiss army knife for your cluster woes"
[taxonomies]
categories = [ "Technical" ]
tags = [ "reference" ]
+++

## Etcd

Configure your environment for interacting with `etcd` via CLI:
`export ETCDCTL_API=3 ETCDCTL_CACERT=etcd.pem ETCDCTL_CERT=kube-apiserver-etcd-client.pem ETCDCTL_KEY=kube-apiserver-etcd-client-key.pem ETCDCTL_ENDPOINTS=localhost:2379`

Inspect all keys:
`etcdctl get --prefix / --keys-only`

Remove leftover Cilium data:
`etcdctl del --prefix /registry/cilium.io/cilium`

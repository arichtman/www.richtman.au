+++
title = "Kubernetes Bootstrapping with Smallstep CLI"
date = 2023-08-26T12:07:57+10:00
description = "I suffered so you don't have to"
[taxonomies]
#categories = [ "Technical" ]
tags = [ "k8s", "tls", "kubernetes", "x509", "mtls", "certificates", "trust" ]
+++

# Kubernetes Bootstrapping with Smallstep CLI

## Problem

You need to bootstrap a kubernetes cluster with certificates.
Everyone copy-paste's Kelsey Hightower's `cfssl` commands.
... or uses `Kubeadm`, `Kubespray` etc...

You have several hours of your life you don't particularly care to enjoy.

## Prerequisites

- `step-cli`
- [Optional] Existing trust chain.

## Procedure

1. [Optional] Root CA creation
1. Intermediate CAs
1. `etcd`
1. `kube-apiserver`

Notes:

- Some of these commands still have my name etc in them.
  Use common sense and adjust as desired.
  As Chef John says, _that's just you cooking_.

## Root CA

1. [Optional] Create password
   `xkcdpass --delimiter - --numwords 4 > root-ca-pass.txt`
1. Create root CA
   `step certificate create "ariel@richtman.example" ./root-ca.pem ./root-ca-key.pem --profile root-ca # Optional --password-file ./root-ca-pass.txt`

Notes:

- Root CAs are usually highly sensitive, the password is recommended, as is storing the private key under MFA.

## Intermediate CAs

These only need a couple of specifics, mostly the capability to be a CA/sign other certs.
I like setting the path length restriction so the trust chain can't be ported any further.

See [downloads](#downloads) for templates and defaults.

```bash
step certificate create kubernetes-ca ./ca.pem ./ca-key.pem  --ca ./root-ca.pem --ca-key ./root-ca-key.pem \
  --ca-password-file root-ca-pass.txt --insecure --no-password --template granular-dn-intermediate.tpl \
  --set-file dn-defaults.json --not-after 8760h
step certificate create etcd-ca ./etcd.pem ./etcd-key.pem  --ca ./root-ca.pem --ca-key ./root-ca-key.pem \
  --ca-password-file root-ca-pass.txt --insecure --no-password --template granular-dn-intermediate.tpl \
  --set-file dn-defaults.json --not-after 8760h
```

Notes:

- You can just use `--profile intermediate-ca` but then the handful that require a specific organization set would be black sheep.
- I'm _pretty_ sure you can only practically use one intermediate CA for all nodes, though it may be possible to bundle stuff.
  I've had enough punishment and I can't see a use case where it would make sense to have different int CAs on every node.
- It _may_ be possible to use the same int CA from k8s for etcd.
  I got pretty far doing that but at one point the k8s CA was being used to authenticate clients and the SAN had to include etcd's hostname.
  This kinda smelled bad enough for me to just go with the recommended way.
- The templating thing feels overkill, I wonder if I could have just constructed the DN and put it in the subject line.
  I do like the way it has defaults that can be optionally overrriden.
- I went spelunking the Smallstep repos and found the built-in templates in the crypto repo under `x509Util`.

## etcd

This one's pretty easy actually.
We need one leaf for TLS and one leaf for the api server client authentication.

The tricky bit is we need to set **just** the organization in the DN to be something special.
Check the official Kubernetes documentation for a table of certificate requirements like this.

```bash
export NODE_DNS_NAME=<yourname>
# etcd TLS
step certificate create etcd etcd-tls.pem etcd-tls-key.pem --ca etcd.pem --ca-key etcd-key.pem \
  --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json --not-after 8760h --bundle \
  --san "${NODE_DNS_NAME}" --san "${NODE_DNS_NAME}.local" --san localhost --san 127.0.0.1 --san ::1
# kube-apiserver
step certificate create kube-apiserver-etcd-client kube-apiserver-etcd-client.pem kube-apiserver-etcd-client-key.pem \
  --ca etcd.pem --ca-key etcd-key.pem --insecure --no-password --not-after 8120h \
  --template granular-dn-leaf.tpl --set-file dn-defaults.json
```

For convenience here's my configuration.

```bash
ETCD_CERT_FILE = "/var/lib/kubernetes/secrets/etcd-tls.pem";
ETCD_KEY_FILE = "/var/lib/kubernetes/secrets/etcd-tls-key.pem";
ETCD_CLIENT_CERT_AUTH = "true";
ETCD_TRUSTED_CA_FILE = "/var/lib/kubernetes/secrets/etcd.pem";
ETCD_PEER_CERT_FILE = "/var/lib/kubernetes/secrets/etcd-tls.pem";
ETCD_PEER_KEY_FILE = "/var/lib/kubernetes/secrets/etcd-tls-key.pem";
```

Once that's confirmed running we can test it using our certificates and the conveniently-installed `etcdctl`.
`etcdctl --cacert ca.pem --cert kube-apiserver-etcd-client.pem --key  kube-apiserver-etcd-client-key.pem --endpoints "${NODE_DNS_NAME}:2379" auth status`

Final step is to close the permissions.
`chown etcd: etcd*; chmod 444 etcd.pem etcd-tls.pem; chmod 400 etcd-*key.pem`
Note that the intermediate public certificate must be readable by kubernetes user, or it's group if you want to get fancy.

Notes:

- I'm not sure I'd bother doing different certificates per-node or not.
  Might help with traceability in the logs for etcd client at least.
  If you _aren't_ doing different certificates per-node, you'll want to add **all** the node DNS entries to the SANs.
- I need to find a nicer way to collate and add the SANs for TLS. Probably nixable.
- Adding loopback and localhost to SANS seems, off.
- If using any more intermediate trust in the TLS chain, you'll probably have to bundle the intermediates.

## kube-apiserver

This one's a beast, since it's basically the heart of the cluster, being the only thing that's allowed to talk to etcd.

First up we have some public certificates only.
The _client ca file_ and _kubelet certificate authority_ can just be the cluster's intermediate CA.
The _etcd ca file_ is `etcd`'s dedicated intermediate CA.

The _etcd certfile_ and _etcd keyfile_ are the leaf client auth certificates we generated in the `etcd` step.

We'll need a few new certificates for this one, all leaf type and only one for HTTPS.

```bash
# For the actual API server's HTTPS
step certificate create kube-apiserver kube-apiserver-tls.pem kube-apiserver-tls-key.pem --ca ca.pem --ca-key ca-key.pem \
  --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json --not-after 8760h --bundle \
  --san "${NODE_DNS_NAME}" --san "${NODE_DNS_NAME}.local" --san localhost --san 127.0.0.1 --san ::1 \
  --san kubernetes --san kubernetes.default --san kubernetes.default.svc \
  --san kubernetes.default.svc.cluster --san kubernetes.default.svc.cluster.local
# For client authentication to kubelets
step certificate create kube-apiserver-kubelet-client kube-apiserver-kubelet-client.pem kube-apiserver-kubelet-client-key.pem \
  --ca ca.pem --ca-key ca-key.pem --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json --not-after 8760h \
  --set organization=system:masters
# For client authentication to the proxy services
step certificate create kube-apiserver-proxy-client kube-apiserver-proxy-client.pem kube-apiserver-proxy-client-key.pem \
  --ca ca.pem --ca-key ca-key.pem --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json \
  --not-after 8760h
```

The last thing we need is a public & private key pair, encoded in x509 for signing service account tokens.

`openssl req -new -x509 -days 365 -newkey rsa:4096 -keyout service-account-key.pem -sha256 \
  -out service-account.pem -nodes \
  -multivalue-rdn -subj /CN=Australia/O=Richtman/OU=Ariel/CN=kubernetes-service-accounts`

Now we can configure that and it should be talking to `etcd` A-OK.

We will now tidy up the permissions.
You'll have to do this again for the component certificates too, but you got this :)

```bash
# Own your certificates
chown kubernetes: kube-apiserver*
# Take ownership of the int-ca files
chown kubernetes: ca*.pem
# Own the service account key pair
chown kubernetes: service-account*

# Open all files
chmod 444 *.pem
# ... but protect the keys
chmod 400 *key*.pem
```

Notes:

- A few of the last ones could probably be the same certificate, but it's a bit nicer probably in tracing to have different CNs.
  Some services auth and assign the username as the CN/DN, which could lead to a lot of confusion.
- A bunch of those kubernetes-ish SANs are just suggestions from the docs, they probably need actual DNS entries to work.
- I definitely wonder now at the addition of SANs for loopback IPs, that feels weird for HTTPS.
- I had hoped we could just `ssh-keygen`, but alas it has to be x509 for the service account pair.
- I have no idea if the service account pair should be rotated or even can be, given that it's used for verification too.
  I _think_ it's possible to use one of the other certificates that we have both sides of. Unsure.
- I'm not actually sure the service account public key has to be open but it would make sense if anything else wanted to verify the tokens

## Remaining core components

```bash
# Control plane nodes
# Controller manager apiserver client
# Note the Subject.CommonName being set not by flags but required arguments
step certificate create system:kube-controller-manager controllermanager-apiserver-client.pem controllermanager-apiserver-client-key.pem \
  --ca ca.pem --ca-key ca-key.pem --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json \
  --not-after 8760h --set organization=system:kube-controller-manager
# Scheduler apiserver client
step certificate create system:kube-scheduler scheduler-apiserver-client.pem scheduler-apiserver-client-key.pem \
  --ca ca.pem --ca-key ca-key.pem --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json \
  --not-after 8760h
# TLS
step certificate create kube-scheduler scheduler-tls.pem scheduler-tls-key.pem --ca ca.pem --ca-key ca-key.pem \
  --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json --not-after 8760h --bundle \
  --san "${NODE_DNS_NAME}" --san "${NODE_DNS_NAME}.local" --san localhost --san 127.0.0.1 --san ::1

step certificate create kube-controllermanager controllermanager-tls.pem controllermanager-tls-key.pem --ca ca.pem --ca-key ca-key.pem \
  --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json --not-after 8760h --bundle \
  --san "${NODE_DNS_NAME}" --san "${NODE_DNS_NAME}.local" --san localhost --san 127.0.0.1 --san ::1
## All node certs
# Flannel apiserver client
# This one depends on your RBAC setup, adjust the CN as required, the O might be uneccessary
step certificate create flannel-client flannel-apiserver-client.pem flannel-apiserver-client-key.pem \
  --ca ca.pem --ca-key ca-key.pem --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json \
  --not-after 8760h --set organization=flannel-client
# Kubelet apiserver client
step certificate create "system:node:${NODE_DNS_NAME}" kubelet-apiserver-client.pem kubelet-apiserver-client-key.pem \
  --ca ca.pem --ca-key ca-key.pem --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json \
  --not-after 8760h --set organization=system:nodes
# Kube-proxy apiserver client
step certificate create system:kube-proxy proxy-apiserver-client.pem proxy-apiserver-client-key.pem \
  --ca ca.pem --ca-key ca-key.pem --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json \
  --not-after 8760h --set organization=system:node-proxier
# TLS
step certificate create kubelet kubelet-tls.pem kubelet-tls-key.pem --ca ca.pem --ca-key ca-key.pem \
  --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json --not-after 8760h --bundle \
  --san "${NODE_DNS_NAME}" --san "${NODE_DNS_NAME}.local" --san localhost --san 127.0.0.1 --san ::1
```

## Onwards

From here forwards you should have a reasonably clear hammer to hit most cert requirements with.
It's basically either for HTTPS and needs a SAN or it's for client auth and it _may_ need the `O` property set.

For convenience, this will fix up all the key permissions:

```bash
chown kubernetes: *.pem
chown etcd: etcd*.pem
chmod 444 *.pem
chmod 400 *key*.pem
```

General notes:

- You could probably just set the organization to `system:masters` on _every_ cert but it feels brutish.
- CSR/config files would be a _bit_ nicer for this, but not as valuable to home lab use case.
- I didn't bother backing up my intermediate CAs, they're essentially disposable.

## References

- [Smallstep cli docs](https://smallstep.com/docs/step-cli/reference/certificate/create/)
- [k8s certificate guide](https://kubernetes.io/docs/setup/best-practices/certificates/#single-root-ca)
- [k8s apiserver cli reference](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
- [k8s tls rotation procedure](https://kubernetes.io/docs/tasks/tls/certificate-rotation/)
- Personal pain

## Downloads

- [Intermediate CA template](granular-dn-intermediate.tpl)
- [Leaf template](granular-dn-leaf.tpl)
- [DN defaults](dn-defaults.json)

[back to procedure](#intermediate-cas)

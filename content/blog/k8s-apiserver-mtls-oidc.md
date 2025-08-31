+++
title = "Securing Public Kubernetes API server access with OIDC"
description = ""
date = 2025-08-31T16:49:20+10:00
draft = true
[taxonomies]
categories = [ "Technical" ]
tags = [ "k8s", "kubernetes", "oauth", "oauth2", "oidc", "security", "auth", "mtls" ]
+++

# Kubernetes without mTLS auth

1. Configure upstream
1. Upstream server override hostname, enable TLS verification
1. Configure location
1. Configure server, enable mTLS
1. Generate valid mTLS client certificates
1. Set kubeconfig client certificates to mTLS ones
1. ??? Make kubeconfig fire exec when asked for auth?

`~/.kube/config`:

```yaml
apiVersion: v1
current-context: home-public
kind: Config
clusters:
- name: public
  cluster:
    server: https://<MY NGINX ADDRESS>
  # certificate-authority: Not needed with public certs!
users:
- name: home-public
  user:
    client-certificate: mtls.pem
    client-key: mtls-key.pem
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: kubectl
      args:
      - oidc-login
      - ...
```

+++
title = "Kubernetes API Server Anonymous Prometheus Monitoring"
date = 2025-08-17T10:23:52+10:00
description = "Quick treat"
[taxonomies]
categories = ["Technical"]
tags = [ "k8s", "kubernetes", "monitoring", "o11y", "observability", "prometheus" ]
+++

## Problem

We want to monitor the Kubernetes API server.
But we don't want to have to manage certificates and overdo our Prom config.

## Analysis

The API server by default protects all paths/resources behind whatever auth it's loaded with.
Anonymous auth is generally discouraged from leaving on, as role bindings (or ABAC, if you're trendy) can leak permissions.
We need to blanked disallow anonymous auth, but allow it on certain paths.

This creates a new problem, namely that `system:anonymous` has no permissions[^1].
We can solve this by creating and binding a role that only allows access to metrics.

## Solution

1. Create a [structured authentication configuration](https://kubernetes.io/blog/2024/04/25/structured-authentication-moves-to-beta/) file.

   ```yaml
   apiVersion: apiserver.config.k8s.io/v1beta1
   kind: AuthenticationConfiguration
   anonymous:
     enabled: true
     conditions:
       - path: /metrics
   # Note: optional, not used here
       - path: /livez
       - path: /readyz
       - path: /healthz
   ```

1. Point `kube-apiserver` at it with flag `--authentication-config`[^2].
1. Create a role that allows `/metrics` access only.

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: raw-metrics
   rules:
   - nonResourceURLs:
     - "/metrics"
       verbs: ["get"]
   ```

1. Now bind this to anonymous.

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     name: anonymous-metrics
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: raw-metrics
   subjects:
   - apiGroup: rbac.authorization.k8s.io
     kind: User
     name: system:anonymous
   ```

1. And finally, add your Prometheus rule, noting the scheme change[^3].

   ```yaml
   - job_name: k8s_apiserver
     scheme: https
     static_configs:
     - targets:
       - my-k8s-apiserver:6443
   ```

## Notes

[^1]: This is not strictly true, `/healthz`, `/livez`, and `/readyz` _are_ accessible without a binding, _if_ you add them to the anonymous auth allowlist.

[^2]: You may need to remove flags like `--oidc-*` and `--anonymous-auth`, and add any OIDC providers to the config file.

[^3]: This sample is bare-bones, there may be more to the rule, depending on your setup.

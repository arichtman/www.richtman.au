+++
title = "Default Containers for Kubectl"
date = 2025-03-30
[taxonomies]
categories = [ "TIL" ]
tags = [ "kubernetes", "k8s", "kubectl" ]
+++

Kubectl commands that offer the `--container` argument can be set to a default Kubernetes-side.
Simply set the annotation `kubectl.kubernetes.io/default-container` to the desired container name.

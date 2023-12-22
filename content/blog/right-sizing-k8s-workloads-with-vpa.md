+++
title = "Right-sizing Kubernetes Workloads with Vertical Autoscaling"
date = 2023-12-20T19:35:58+10:00
description = "Nobody ever does this one weird trick"
[taxonomies]
categories = [ "Technical" ]
tags = [ "k8s", "kubernetes", "vpa", "scaling", "containers" ]
+++

# Right-sizing Kubernetes Workloads with Vertical Autoscaling

## Problem

We have some workload we want to run on Kubernetes.
We want to have an efficient mix of CPU and RAM.

[Just take me to the fix!](#solution)

## Analysis

Requests are the minimum resources that your pod will have.
CPU requests are typically guaranteed on the node by Completely Fair Scheduler cgroups.
Memory requests are not compressible on Kubernetes, though are served also by cgroups.

Workloads may consume more than they request, provided the resources are a) available on the node, and b) not in excess of the specificied resource limits.
This means workloads can affect other workloads (noisy neighbours).
This includes node-critical processes like the operating system or the kubelet, kube-proxy, etc.
Though critical processes _should_ bet set with Quality-of-Service (QoS) of `Guaranteed`.

Requests are also crucial information for scheduler bin-packing.
If a workload has no indication of what it needs to run, it's impossible for the scheduler to efficiently and safely pack the nodes.

For these reasons, it's generally advised to set the limit to the request for memory, and no limit for CPU.
That way memory consumption won't blow out, and some applications that don't play nicely with dynamic memory changes, like Java, won't waste the additional space.
CPU is ensured for the lowest amount required but can burst.
Since the CPU can be shared, your node won't jam up completely and be unrecoverable.

It's worth noting that pod `Priority` or `PriorityClass` won't help with resource sharing.
These only affect scheduling and eviction.

_Vertical Pod Autoscaler_ (VPA) is a Kubernetes project component.
It's not as ubiquitous or well-supported as the _Horizontal Pod Autoscaler_ (HPA).
The VPA lacks a Helm chart and officially uses shell scripts to install.

The VPA has three (3) components; an _AdmissionController_, a _Recommender_, and an _Updater_.
(There are a bit more pieces to this, but that's all the functional bits really)

The _Recommender_ monitors the _Custom Resource_ `VerticalPodAutoscaler`, reviews the history, and patches the object with recommendations.
Here's what that looks like.

Everything under spec, we defined.
Everything under status, was set by the _Recommender_.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: sample
spec:
  resourcePolicy:
    containerPolicies:
    - containerName: '*'
      controlledResources:
      - cpu
      - memory
      minAllowed:
        cpu: 100m
        memory: 50Mi
      maxAllowed:
        cpu: 4
        memory: 8Gi
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample
  updatePolicy:
    updateMode: Auto
status:
  conditions:
  - lastTransitionTime: "2023-12-20T06:45:57Z"
    status: "True"
    type: RecommendationProvided
  recommendation:
    containerRecommendations:
    - containerName: sample
      lowerBound:
        cpu: 100m
        memory: 262144k
      target:
        cpu: 100m
        memory: 262144k
      uncappedTarget:
        cpu: 25m
        memory: 262144k
      upperBound:
        cpu: 128m
        memory: "578209822"
```

The _Updater_ monitors the same custom resource, but evicts pods if the spec says to.
The property for this is `updatePolicy/updateMode`, which defaults to `Auto`.
Auto setting will apply recommendations and evict pods eagerly.
Other options are `Off`, `Initial`, and `Recreate`.
For right-sizing, we want either `Auto` or `Off`.
Don't worry, `Off` will still set recommendations.

The _AdmissionController_ is called by a `MutatingWebhookConfiguration`, and dynamically modifies the resources on recreated pods.

## Solution

The workflow is as follows:

1. Install the VPA component.
1. Launch your workload as one pod, with minimal resource requests.
1. Create a `VerticalPodAutoscaler` object for your workload.
1. Apply load to the service and observe.
1. Amend your `resources` specification.
1. Repeat last two steps.
1. Remove the `VerticalPodAutoscaler` object.

If you used `Auto`, it takes care of updating the pods for you.
However you may find things move too quickly for you to assess the application under load.

You may wish to apply production-like load, take the recommendation, and call it a day.
You may also wish to apply increasing load until the error rate of your application is unacceptable, then use that as limits.
You may decide to leave it automatically scaling forever!
If one pod is enough vertically scaled then so be it.

## Notes

The recommender is not node-group aware, so it is possible that it sets requests that cannot be fulfilled even with cluster autoscaling.
You likely want to avoid this situation, so consider temporarily adding a large node, and using taints/affinity to schedule your testing load there.

There is an alpha feature for Kubernetes on Linux to allow in-place resource changes.
We're waiting for that to stabilize before testing it out.

The VPA stores eight (8) days of rolling history if no back-end storage is configured (i.e. Prometheus' TSDB).
This can foul iteration, as your highest recommendations keep returning.
To address this, delete your application's `VPACheckpoint`, and restart the _Recommender_ service.

The default _Updater_ configuration sets the Minimum number of replicas to perform update to two (2).
This will not update our little one-pod deployment, and needs to be set to one (1) for our workflow to work.

While the VPA should not be combined with the HPA, the VPA still supports updating multiple pods.
Once you've right-sized on a single pod, try scaling out with the VPA still active, and see if it tunes them up or down.
The performance characteristics of a load-balanced system may differ.

## References

- [VPA readme and FAQ](https://github.com/kubernetes/autoscaler/blob/master/vertical-pod-autoscaler/README.md)
- [Kubecost VPA explainer](https://www.kubecost.com/kubernetes-autoscaling/kubernetes-vpa/)
- [Third-party Helm chart](https://github.com/cowboysysop/charts/tree/master/charts/vertical-pod-autoscaler)
- [VPA persistence issue](https://github.com/kubernetes/autoscaler/issues/4682#issuecomment-1384015090)
- [VPA history issue](https://github.com/kubernetes/autoscaler/issues/4476#issuecomment-981456744)
- [Kubernetes QoS docs](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/)
- [QoS talk](https://youtu.be/8-apJyr2gi0)
- [Numerator engineering article about CPU limits and throttling](https://www.numeratorengineering.com/requests-are-all-you-need-cpu-limits-and-throttling-in-kubernetes/)
- [Kubernetes resource management docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

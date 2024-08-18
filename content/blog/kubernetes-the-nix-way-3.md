+++
title = "Kubernetes the Nix Way - Part 3"
date = 2024-08-18T19:07:06+10:00
description = "Little wires"
[taxonomies]
categories = [ "Technical" ]
tags = [ "nix", "nixos", "kubernetes", "k8s", "k8s-nix-way" ]
+++

## Kubernetes the Nix Way - Part 3

Today, we move on to doing the kubelet.
In this article we'll see about writing and using configuration files, as well as improving our cross-configuration Nix wiring.

So to begin, we need a `kubelet.nix` file, where we'll store our implementation of both the options, and the implementation.
The kubelet is rather useless without a container management service, which in turn requires a container runtime.
Together, these are used to implement the _Container Runtime Interface_ (CRI).
This is a consistent interface that's used to decouple the kubelet from the implementation of actually managing and running containers.
We can leverage an existing NixOS module for this `virtualisation.containerd`.

Containerd was originally the Docker daemon, but was since split out into it's own project for purposes of interoperability.
How nice of them!

```nix
config = lib.mkIf cfg.enabled {
  virtualisation.containerd = {
    enable = true;
  };
```

We don't really need the kubelet on a control node at all, but it does make it a bit nicer to manage via `kubectl`, so we'll add it.
Strictly speaking, the kubelet shouldn't actually need the container runtime or service.
However, it assumes it's presence and blows up without it.
It's probably possible to set a dummy CRI but that's out of scope for our adventure.

The kubelet is deprecating command-line arguments in favor of a configuration file.
This is nicer as we can do data structure composition and just serialize to disk, rather than munging strings.
However it will mean we need a bit of a different approach.
Let's start with the service definition.

```nix
systemd.services."k8s-kubelet" = {
  description = "Kubernetes Kubelet Service";
  after = ["network.target"];
  serviceConfig = {
    Slice = "kubernetes.slice";
    ExecStart = "${pkgs.kubernetes}/bin/kubelet" +
      " --config" + " ${kubeletConfigFile}";
    WorkingDirectory = "/var/lib/kubernetes";
    Restart = "on-failure";
    RestartSec = 5;
  };
};
```

Now we'll have to construct the kubelet configuration file.
But first, an important but irritating distinction:

**The kubelet configuration file has nothing to do with a kubeconfig file!**

A further point of irritation is that not all CLI arguments are available in the config file API.
You have to reference the CLI documentation to see if it's got a deprecation notice.
If not, we'll have to add it as a CLI argument.
Talk about the worst of both worlds...
With that ado, let's set about creating our config file.

```nix
cfg = config.services.k8s-kubelet;
kubeletConfig = {
    apiVersion = "kubelet.config.k8s.io/v1beta1";
    kind = "KubeletConfiguration";
    enableServer = true;
    tlsCertFile = "${config.services.k8s-apiserver.secretsPath}/kubelet-tls-cert-file.pem";
    tlsPrivateKeyFile = "${config.services.k8s-apiserver.secretsPath}/kubelet-tls-private-key-file.pem";
    tlsMinVersion = "VersionTLS12";
    authentication = {
      x509 = {
        clientCAFile = "${config.services.k8s-apiserver.secretsPath}/ca.pem";
      };
      webhook = {
        enabled = true;
        cacheTTL = "10s";
      };
    };
    authorization = {
      mode = "Webhook";
    };
    clusterDomain = "local";
    imageMaximumGCAge = "604800s";
  };
```

Now `config.services.k8s-apiserver.secretsPath` seems kindof verbose.
But we already have a reference to our config up top to shorten this sort of thing.
Let's add another and clear this up.

```nix
mainK8sConfig = config.services.k8s;
kubeletServiceConfig = config.services.k8s-kubelet;
kubeletConfig = {
  apiVersion = "kubelet.config.k8s.io/v1beta1";
  kind = "KubeletConfiguration";
  enableServer = true;
  tlsCertFile = "${mainK8sConfig.secretsPath}/kubelet-tls-cert-file.pem";
  tlsPrivateKeyFile = "${mainK8sConfig.secretsPath}/kubelet-tls-private-key-file.pem";
  tlsMinVersion = "VersionTLS12";
  authentication = {
    x509 = {
      clientCAFile = "${mainK8sConfig.secretsPath}/ca.pem";
    };
    webhook = {
      enabled = true;
      cacheTTL = "10s";
    };
  };
  authorization = {
    mode = "Webhook";
  };
  clusterDomain = "local";
  imageMaximumGCAge = "604800s";
};
kubeletConfigFile = pkgs.writeText "kubelet-config" (builtins.toJSON kubeletConfig);
```

So this explains [the original module's](https://github.com/NixOS/nixpkgs/blob/cc90561a8fb233a54460b095110605171ea6578a/nixos/modules/services/cluster/kubernetes/kubelet.nix#L7)
use of multiple configuration assignments!
We can see now how this will help tame the chaos of cross-referencing multiple modules' configuration.

Now we have a configured binary launching, it'll need API server access.
It *is* technically possible to launch it in a standalone mode, but we don't want that for this application.
Kubelet access to the API server is done like any other user, with a Kubeconfig file.
So, much the same dance as before, just this time a different API specification.

```nix
kubeletKubeconfig = {
  apiVersion = "v1";
  kind = "Config";
  users = [
    {
      name = "kubelet";
      user = {
        client-certificate = "${mainK8sConfig.secretsPath}/kubelet-kubeconfig-client-certificate.pem";
        client-key = "${mainK8sConfig.secretsPath}/kubelet-kubeconfig-client-key.pem";
      };
    }
  ];
  clusters = [
    {
      name = "default";
      cluster = {
        certificate-authority = "${mainK8sConfig.secretsPath}/ca.pem";
        server = "https://fat-controller.local:6443";
      };
    }
  ];
  contexts = [
    {
      name = "default";
      context = {
        cluster = "default";
        user = "kubelet";
      };
    }
  ];
  current-context = "default";
};
kubeletKubeconfigFile = pkgs.writeText "kubelet-config" (builtins.toJSON kubeletKubeconfig);
```

...and we mustn't forget to feed this to the process arguments.

```nix
systemd.services."k8s-kubelet" = {
  description = "Kubernetes Kubelet Service";
  after = ["network.target"];
  wantedBy = [ "kubernetes.target" ];
  serviceConfig = {
    Slice = "kubernetes.slice";
    ExecStart = "${pkgs.kubernetes}/bin/kubelet" +
      " --config" + " ${kubeletConfigFile}" +
      " --kubeconfig=${kubeletKubeconfigFile}" +
    WorkingDirectory = "/var/lib/kubernetes";
    Restart = "on-failure";
    RestartSec = 5;
  };
};
```

Bonus tidbits:

- `imageMaximumGCAge` didn't recognise `d` as a unit, so I defaulted back to `s`, which it understands.
- `virtualisation.containerd` doesn't expose the socket location as a configuration item, so we couldn't link that directly.
- Kubelet configuration is an odd mix of casing sometimes. `authentication.webhook` is all camelCase, but `authorization.mode` MUST be `Webhook`, in PascalCase.
  Simples!
- I wasn't able to find a way to set the API server address in the Kubelet config file.
  It looks like it _must_ be set in the kubeconfig file, which makes some sense I suppose.
- `containerRuntimeEndpoint` is a mandatory kubelet configuration entry, and while it doesn't state a default, it does actually default correctly on Linux with `containerd`.
  This makes sense when we consider historically close integration between Docker and Kubernetes.
- Until a drop-in kubelet file configuration directory is enabled and defaulted, we'll just point it directly at the Nix store path.
  However, we may end up writing them to whatever `/etc/kubelet/conf.d` directory instead.
- The kubelet throws a tantrum if it's not the root user.
  I'm not sure if there's any way around this but it's certainly not ideal.
  **Remember: when you grant admin to your API server, you're granting `root` to every node as well!**
- Note the spaces in the string arguments to the kubelet, this isn't pretty, we might clean that up later.

## References

- [State of work](https://github.com/arichtman/nix/tree/82a6abf5f6ef059c60c4e206b30c4b75d37e5b74/modules/nixos/k8s)
- [Kubelet configuration API](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1)
- [Kubelet CLI reference](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
- [Kubeconfig cluster access](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)

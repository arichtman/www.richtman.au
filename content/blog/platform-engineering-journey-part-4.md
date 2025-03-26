+++
title = "Platform Engineering Journey - Part 4"
date = 2025-03-26T21:20:57+10:00
description = "Dreaming..."
draft = true
[taxonomies]
categories = [ "Meta" ]
tags = [ "platform-engineering", "platform-engineering-journey" ]
+++

Note: you may wish to read these in order or at least the [organizational context](./platform-engineering-journey-part-0.md)

# Vision

Genuinely joy-bringing, silverrail-specific abstraction of infrastructure and cloud.

I'm thinking a single configuration file in the repo.
TOML or YAML, we can probably support JSON too it's all workable with a little ingest logic.

```toml
[silverone]
version = "v1.3.2"

[silverone.applications.my-app]
images = [ "nginx", "redis" ]
size = "medium"
ingress = true
```

<!-- pyml disable-next-line no-trailing-punctuation,md026 -->
## The Clearer You See...

Transformation. The tool should be able to purely functionally and deterministically derive a full set of Kubernetes manifests based on the config file and silverlift.
Some tools offer this, but I really want it client-side. When it's buried inside containers and Kubernetes it becomes much harder to inspect and debug.
Being able to build the full output locally means seeing what changes as you adjust inputs and versions.
Crossplane offers some form of transformation but it's based on stdin and arbitrary containers.
It will _work_ but it's very opaque and will be a nightmare to troubleshoot as finding out what the call was precisely is difficult and replicating it locally tedious.
Kro is a hot new project, though it is a partnership between major cloud providers.
I like that it creates CRDs for you, and it could mean developers maintain a single YAML file, as well as having the API versioned.

Versioned transformations. We need to be able to evolve the tool, bugfix, etc.
So whatever is imported to do the transformation has to be selectable early with a version.
We could do this with git modules but the UX of those is awful.
Ideally the tool natively supports pulling from arbitrary git repos or at worst HTTP endpoints.
If CLI tool, we definitely don't want to be keeping all the prior logic versions around in the tool so no like, subcommands `tool --version 0.45.2`.
The code base and binary would blow out.
We'd want the version of the tool pinned elsewhere, Nix flake would work, but then should we be focussing on pure Nix derivations?
We could do Nix derivations _using_ the tool, which would be cool, e.g. `nix build` and `./result/manifest.yaml`.

Escape hatches. The tool needs some equivalent to shelling out to do custom transformations.
This means development teams aren't constantly blocked behind us at the start, and we can actually incorporate their work later as things prove popular.
Ideally, to do this we allow the configuration file to pass functions as a first class citizen, and implement an API exposing at least a `postProcessing` hook.
If not that then perhaps quite literally a shell out,
or perhaps the equivalent of a stored procedure that runs JQ/YQ with some context loaded, possibly environment (as in deployment) dependent.

Per-environment variation. Pretty simple, need to be able to compose values based on target deployment environment.
The dumbest form of this might be concatenating files, not sure if TOML and YAML support this, JSON definitely not.
So probably need at least a merge with precedence.

Ad-hoc environment configurations. Often developers want to test a feature branch, or debug on an old version.
Creating an environment like this shouldn't be onerous.
This one is at the intersection with the deployment tool itself, and may depend on that.

Interface discovery. As much as possible versions of the config file schema should be discoverable and documented.
If we can at _least_ generate JsonSchema that'd be good. Unsure if OpenAPI would be suitable, probably not as much of the HTTP part is irrelevant.

Syntax. Invalid configuration in the root file should be clearly communicated and easily gathered by users.
Propagating source errors fromt he parsing library would work for basic TOML/YAML issues.
Not clear how we'd do more complex validation, probably read in the file,
strategy pattern in the JsonSchema from static in the codebase, then run a checker library and error source propagate.

Writing it in code. We can generate structs most likely from the OpenAPI spec. That part would be manual with the output files stored statically in-repo.
This would mean the tool would come with support for various Kubernetes versions. It would also mean compilation and release required for every API evolution.
We'd need to solve for some amount of code reuse, as say `v1alpha1` of a resource might share a lot of business logic with `v1beta1`.
Traits and implementations could work for this, say we had `fn with_cpu_request(amount_millis: u64)`.
I'm concerned this would yield a lot of boilerplate - is that such a concern though given the k8s release cadence?
Presumably serializing these structs would yield API-compliant YAML/JSON.
Does it make that much sense to duplicate the API restrictions/structure *in* the code though?
On one paw, the typing and enumeration would help ensure business logic is correct.
On the other paw, we're likely going to have to rely on `--dry-run=server` for actual correctness checks.
Of course that check requires cluster and network, which means it's going to be farther along in the lifecycle and less frequent.
The tool could also include the k8s SDK and offer a cluster-verified option...

Errors and recovery. How do users know there's been an error applying IaC? How can they recover it?
What's the searchability of the error and the applicability of results like?
We want to present any errors verbatim for salience and research.
If there's common approaches to fixes, we should enable those or at least have an alternative or analagous approach, with an extremely clear path to adapting to use.

Kubernetes resources are well solved for. Take this from the other end and solve for AWS and arbitrary IaC resources first, as that's the area of greater risk.

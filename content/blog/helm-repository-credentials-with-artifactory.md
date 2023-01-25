+++
title = "Helm repository credentials with Artifactory"
date = 2023-01-25T13:53:50+10:00
description = "Dancing with the devil"
[taxonomies]
categories = [ "Technical" ]
tags = [ "helm", "k8s", "kubernetes", "security" ]
+++

## Problem

We need to authenticate to a private chart repository.
We would like to record this repository's configuration so we don't have to log in every time and can share it.
However, we don't want to accidentally apply those credentials to any externally-owned chart repositories.

## Analysis

We are given the option to provide a username and password when performing `repo add`, `install`, and `upgrade`.
There may be other actions that support it but these are what we will focus on today.
A `repo add` will store the repository's configuration in a YAML file.
The file contains plain text username and password, as well as the URL.
We can control the config property `pass_credentials_all` by setting `--pass-credentials` during the add action.
If `pass_credentials_all` is set, however, the credentials will be passed to any arbitrary repository that might be nominated.
This can leave us vulnerable to confusion attacks and leak credentials.

## Solution

Artifactory manages the index file on Helm repositories.
When it creates this `index.yaml` it puts port suffixes on all FQDNs.
This causes Helm to fail to match the config to the repository it's using.
By ensuring the config file has the port suffix, it should recognise and pass auth headers.
Because this is set per-repo configured, we don't have to muck with other repos that _do_ follow RFC 3986.
There are two ways to set this:

- When `helm repo add`ing the Artifactory repo, specify the port number
- Adjust an existing config file to add the port number

Potential other workarounds:

- Using an arbitrary repository and self-managing the index file and tarballs
- Using an OCI registry to store the charts

## References

- [Helm security advisory](https://github.com/helm/helm/security/advisories/GHSA-56hp-xqp3-w2jf)
- [Artifactory issue 26063](https://jfrog.atlassian.net/browse/RTFACT-26063)
- [Artifactory issue 27496](https://jfrog.atlassian.net/browse/RTFACT-27496#icft=RTFACT-27496)
- [GitHub PR on port confusion](https://github.com/helm/helm/pull/10616)

## Appendix

Full test results

| Case # | Config URL            | Install `--pass-credentials` | Install `--repo`      | Outcome                 |
|--------|-----------------------|------------------------------|-----------------------|-------------------------|
| 1      | https://repo.fqdn     | FALSE                        | FALSE                 | 401   on the tarball    |
| 2      | https://repo.fqdn     | TRUE                         | FALSE                 | 401 on the tarball      |
| 3      | https://repo.fqdn     | FALSE                        | https://repo.fqdn     | 401   on the index.yaml |
| 4      | https://repo.fqdn     | TRUE                         | https://repo.fqdn     | 401 on the index.yaml   |
| 5      | https://repo.fqdn     | TRUE                         | https://repo.fqdn:443 | 401   on the index.yaml |
| 6      | https://repo.fqdn     | FALSE                        | https://repo.fqdn:443 | 401 on the index.yaml   |
| 7      | https://repo.fqdn:443 | FALSE                        | FALSE                 | Works!                  |
| 8      | https://repo.fqdn:443 | TRUE                         | FALSE                 | Works!                  |
| 9      | https://repo.fqdn:443 | FALSE                        | https://repo.fqdn     | 401   on the index.yaml |
| 10     | https://repo.fqdn:443 | FALSE                        | https://repo.fqdn:443 | 401 on the index.yaml   |
| 11     | https://repo.fqdn:443 | TRUE                         | https://repo.fqdn:443 | 401   on the index.yaml |

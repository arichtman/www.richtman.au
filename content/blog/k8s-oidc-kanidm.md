+++
title = "Kubernetes OIDC auth with Kanidm"
description = "Just that little bit less clunky"
date = 2025-08-31T16:44:14+10:00
[taxonomies]
categories = [ "Technical" ]
tags = [ "k8s", "kubernetes", "oauth", "oauth2", "oidc", "kanidm", "security", "auth" ]
+++

High-level we need to:

1. Create an Oauth2 client in Kanidm
1. Tell the Kubernetes API server to to trust Kanidm as an Identity Provider (and where to find it)
1. Bind some permissions to OIDC-authenticated users
1. Configure our `kubectl` client to use OIDC

## Create an Oauth2 client in Kanidm

Since we don't want to be shipping our client secret to every user,
nor making a new client for every user, we opt for a trustless client/implicit/PKCE flow.

```bash
export MY_APISERVER_ADDRESS="k8s.internal"
export MY_APISERVER_PORT=6443

# Create the client
kanidm system oauth2 create-public k8s Kubernetes "https://${MY_APISERVER_ADDRESS}:${MY_APISERVER_PORT}"

# Optionally, since Kubernetes has no way to initiate an authentication flow
#   set a landing page that users will hit if they click on the application in Kanidm
kanidm system oauth2 set-landing-url k8s "https://kubernetes.io/"

# Allow localhost redirects, so later our kubectl plugin can catch the tokens
#   by redirecting to itself listening locally.
kanidm system oauth2 enable-localhost-redirects k8s

# Create and map group
kanidm group create k8s_users
# Set the client to map the scopes we need the claims of
kanidm system oauth2 update-scope-map k8s k8s_users openid email profile groups

# Add our user
kanidm group add-members k8s_users $(whoami)

# Repeat this for another new group, k8s_admins

# Verify our work
kanidm system oauth2 get k8s
```

## Configure the Kubernetes API server to be an Oauth2 client

Set the `--authentication-config` argument to a config file.
The url points to a well-known discovery endpoint with a structured config file, that'll give the API server everything else it needs.
It's interesting to look at, check it by hitting `https://<MY KANIDM ADDRESS>/oauth2/openid/k8s/.well-known/openid-configuration`.

`auth-config.yaml`:

```yaml
apiVersion: apiserver.config.k8s.io/v1beta1
kind: AuthenticationConfiguration
jwt:
- claimMappings:
    groups:
      claim: groups
      prefix: ''
    username:
      claim: preferred_username
      prefix: ''
  issuer:
    audiences:
    - k8s
    url: https://<MY KANIDM ADDRESS>/oauth2/openid/k8s
```

## Give permissions to Oauth2 users

The identity token has claims about our group membership.
This means can bind `ClusterRoles` and `Roles` to groups in Kanidm.
Here we bind a couple out-of-the-box `ClusterRole`s to our groups.
One view only for users, and another full admin for admins.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kanidm-users
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: k8s_users@<MY KANIDM ADDRESS>
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kanidm-admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: k8s_admins@<MY KANIDM ADDRESS>
```

## Configure the client

Finally, we need to let the client know to initiate an implicit auth flow.
We'll be using [the kubelogin plugin](https://github.com/int128/kubelogin) to do this, as it'll handle making the calls, receiving the token, and transforming it into
the required schema for `kubectl`.

`~/.kube/config`:

```yaml
- name: oauth
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: kubectl
      args:
      - oidc-login
      - get-token
      - --oidc-issuer-url
      - https://<MY KANIDM ADDRESS>/oauth2/openid/k8s
      - --oidc-client-id
      - k8s
      - --oidc-extra-scope
      - 'openid profile groups email'
```

## Notes

- I don't think the identity token is supposed to be used to access the Service Provider,
  I'm still learning the nuances of Oauth2+OIDC and there's a bit of magic using the kubectl plugin reformatting tokens.
- I could probably hone the scopes down a little, it's not exactly sensitive stuff though.
- It _may_ be possible to do something cool and dynamic here with ABAC, I would like to look into it later.
- I did take a stab at using `step-cli` for the `kubectl` configuration but it has no caching or refresh facilities.
  It's supposed to be used to retrieve a certificate immediately from `step-ca` and not much else it seems.
- You probably want to use a verified email for username, rather than something like `preferred_name` which;
  a) is user-mutable, b) is probably not enforced unique.

## References

- [Kubernetes docs on auth config](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#using-authentication-configuration)
- [Auth config beta announcement](https://kubernetes.io/blog/2024/04/25/structured-authentication-moves-to-beta/)
- [KEP](https://github.com/kubernetes/enhancements/issues/3331)
- [Endpoints](https://id.richtman.au/oauth2/openid/k8s/.well-known/openid-configuration)
- [Video tutorial](https://www.youtube.com/watch?v=kQnXsTPCVXg)
- [Blog post](https://blog.stonegarden.dev/articles/2024/12/kubernetes-rbac/#openid-connect-authorisation)
- [Plugin docs](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins)
- [KEP for external credential providers](https://github.com/kubernetes/enhancements/blob/master/keps/sig-auth/541-external-credential-providers/README.md)

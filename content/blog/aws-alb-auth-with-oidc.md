+++
title = "AWS ALB auth using OIDC via GitLab"
date = 2023-11-29T14:39:19+10:00
description = "T'aint much but it's handy"
[taxonomies]
categories = [ "Technical" ]
tags = [ "aws", "ec2", "alb", "gitlab", "auth", "oidc", "authorization", "authentication" ]
+++

## Problem

We want to protect our website or API.
But we don't want to have to manage API keys, directories, rotation etc.

## Procedure

1. Create an ALB
1. Since we need TLS, add a DNS CNAME record for the load balancer
1. Get a valid certificate in ACM
1. Create an application
   - Redirect URL should be `https://$CNAME/oauth2/idpresponse`
   - Confidential
   - Scope: openid, no others
1. Submit/create
1. Keep the subsequent information handy
1. Add an HTTPS listener to your ALB
1. Add a rule to your listener and enable OpenID
1. On that rule, add a condition for path `/*`
1. Apply the client ID and secret from the application we created.
   You can find the rest of the required information at `https://$OIDC_IDP/.well-known/openid-configuration`
   Here is where you can use a custom scope, if you need.
1. Save it all and test!

## Notes

- I used a personal GitLab application for this, but the steps should be about the same for any Oauth-compliant IdP.
- AWS docs say the redirect URL can be the actual ALB's DNS.
  I'm not sure how that's supposed to work with the `hostname` header and TLS.
- Scope on the application side can be different, check what your IdP supports, the ALB can be configured for it.
- The listener _must_ be HTTPS, it's disabled otherwise as your app secrets would be leaked.
- You can use different conditions/paths etc, we're just blanket gating everything here.

## References

- [AWS ELB docs](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-authenticate-users.html#oidc-requirements)
- [GitLab OIDC docs](https://docs.gitlab.com/ee/integration/openid_connect_provider.html)
- [GitLab OAuth docs](https://docs.gitlab.com/ee/integration/oauth_provider.html)

+++
title = "Keyless AWS auth from GCP"
date = 2025-12-03T18:17:54+10:00
description = "Tractable security"
draft = false
[taxonomies]
categories = [ "Technical" ]
tags = [ "aws", "gcp", "auth", "oauth2", "oauth", "oidc", "authorization", "authentication" ]
+++

## Problem

We want external, _human_ users to be able to access our resources via AWS APIs
(e.g. read a bucket).
We don't want to hand out any long-lived keys or IAM users.
We can't use IAM Identity Center, it only supports one Identity Provider and that's in use for our company workforce.
We don't want to use AWS's IAM _Identity Provider_ with [SAML](https://auth0.com/blog/how-saml-authentication-works/)
as it only supports the browser and copying credentials out of cookies is nasty.

## Analysis

Effectively, we tell AWS to trust GCP's attestations of users.
Then, we rely on the signed [JWT](https://www.jwt.io/introduction) identity attestation, to know who's trying to access AWS.
By trusting this JWT attestation, we achieve *authentication*, we know *who* the user is.
To achieve *authorization*, we allow certain _authenticated_ users to assume an AWS role.

![Keyless AWS access from GCP](./keyless-gcp-aws.drawio.svg)

The token GCP returns to us once authenticated looks like so:

```json
{
  "access_token": "ya28.A0ATi6K2tQIoNB9X2AKBLF9xbsC-owX1QLTYGk97xp1n2Y-Dw21I8BeQU7r7n-RozAA6gdQnPwBlWf5EwmDTN_DZzHilQlP6ZuQfCaIES_jbQa6dVNWi02N3mSezSyiUzH7oWGwy5waOZQuG4AyKrHJg_DhM-51zly-LehSWVgZVEQkiBCNNqckZB5-92w3LrlFZW9OU_dcZyod7sv5kLqeIKqPxszz_c4BNRq-3WP9tteEIWVNmRUciWrcrD3ANrG7cv2ium1gyFaU_vebhfhRpY3R_N9OfJGjgaCgYKAXkSARESFQHGX2MiF7tkkvN8pbqqkyh7QO0ppQ0297",
  "expires_in": 3597,
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6ImQ1NDNlMjFhMDI3M2VmYzY2YTQ3NTAwMDI0NDFjYjIxNTFjYjIzNWYiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIxMjU0OTIzNzUwMzItbWlybTQzNXN2cWJwYWwzZmY4dm0ya3Z0azAyM2VzZjguYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiIxMjU0OTIzNzUwMzItbWlybTQzNXN2cWJwYWwzZmY4dm0ya3Z0azAyM2VzZjguYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDMyMDQ3NzA1NDg2ODg5MjEzOTgiLCJhdF9oYXNoIjoiUzFfRUR6S0RrUmZTbllEVER3VF9XQSIsImlhdCI6MTc2NDkwMDE0NSwiZXhwIjoxNzY0OTAzNzQ1fQ.n1KhCx2EvX4QSvlWjzdLG8qVeIUtrWukg2W_Ljf1EkAEaofVYpnu9PBfpkaPcLfVg5Xa1JxnpYAm56TRjq3CJKpfXB1OTrFdg3z3Wca3bL4x-LuR5Cyx67zrNpfmZ6bn1RGdhfe9E6ylWcrscl7zMD0EyTOwCkCf8Lh69C4DEimaKOVOHZggJJoZoa59J2Y7vfHUnlb9Jx77sEaSyK6O9bnJ9iQNIyIU880yGiPc2NA9O8IpSH8Yh4Cjxv0hw9aVqNXwwy_Cc5_Z5m8SmyoWeXAh0VQZhCSWaRZy5Ppns8Wn8NZJRxM3nJAqwu2qWlyz3_1dBYKkWh7EU1tBRNAYsQ",
  "scope": "openid",
  "token_type": "Bearer"
}
```

Nominally, we should be using the `access_token` against the GCP APIs, and it would grant us whatever scopes we requested (and were granted by the user).
However! We don't want to access the GCP API, we want AWS.

Decoding the JWT in the `id_token` field yields the signed payload.

```json
{
  "iss": "https://accounts.google.com",
  "azp": "999999999999-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com",
  "aud": "999999999999-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com",
  "sub": "777777777777777777777",
  "at_hash": "S1_EDzKDkRfSnYDTDwT_WA",
  "iat": 1764900145,
  "exp": 1764903745
}
```

We can use this attestation in our AWS policies now.
It's somewhat limited since we don't have any more claims like groups, so we'll have to map one GCP Oauth application to one role to maintain granular control.

## Solution

### GCP

1. Create Oauth App.
1. Create Oauth Client:
   - Name: Anything you desire
   - Type: Web application
   - Authorized redirect URIs:
     Depends, for Step-CLI it will be whatever we set the argument to,
     and for OIDC-CLI it was `http://localhost:9555/callback`
1. Note the client ID and secret.

### AWS

1. Create a role with whichever permissions you want.
1. Set the trust policy to allow Oauth users to assume it based on audience.
   Note that this **must** match the issuer and audience to be secure.
   If we don't set the issuer correctly, anyone who has access to the issuer's domain could sign attestations and gain access.
   If we don't limit the audience, then attestations signed _for another application_ would get access.
   For additional security, limit the subject as well.
   This will mean both sides need to make a change to allow additional users access.

```json5
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "accounts.google.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "accounts.google.com:aud": "999999999999-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com",
          "accounts.google.com:sub": ["555555555555555555555", "666666666666666666666"]
        }
      }
    }
  ]
}
```

### Usage

```bash
export AWS_ROLE_SESSION_NAME="$(whoami)"
export AWS_WEB_IDENTITY_TOKEN_FILE='./token.txt'
export AWS_ROLE_ARN='arn:aws:iam::888888888888:role/MyGCPRole'
# Used for login hint to GCP Oauth prompt
export MY_EMAIL=ariel.richtman@silverrailtech.com
export ISSUER=https://accounts.google.com
export CLIENT_ID=999999999999-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com
export CLIENT_SECRET=GOCSPX-bbbbbbbbbbbbbbbbbbbbbbbbbbbb

# Get our GCP attestation...

# ...using Step CLI
step oauth --provider https://accounts.google.com \
--client-id $CLIENT_ID \
--scope "openid" \
--listen "localhost:5000" \
--prompt none \
--client-secret $CLIENT_SECRET \
| jq -r ' .id_token ' > $AWS_WEB_IDENTITY_TOKEN_FILE

# ... or OIDC-CLI
./oidc-cli authorization_code \
-login-hint $MY_EMAIL \
-issuer $ISSUER \
-client-id $CLIENT_ID \
-pkce \
-state $(uuidgen) \
-scopes "openid" \
-client-secret $CLIENT_SECRET \
| jq -r ' .id_token ' > $AWS_WEB_IDENTITY_TOKEN_FILE

# Assume the role using the token we pulled

aws sts assume-role-with-web-identity \
--role-arn $AWS_ROLE_ARN \
--role-session-name $AWS_ROLE_SESSION_NAME \
--web-identity-token "file://${AWS_WEB_IDENTITY_TOKEN_FILE}"

# Here's the infamous assume-role one-liner

printf "AWS_ACCESS_KEY_ID=%b\nAWS_SECRET_ACCESS_KEY=%s\nAWS_SESSION_TOKEN=%s" \
  $(aws sts assume-role-with-web-identity \
--role-arn $AWS_ROLE_ARN \
--role-session-name $AWS_ROLE_SESSION_NAME \
--output text \
--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
--web-identity-token "file://${AWS_WEB_IDENTITY_TOKEN_FILE}") > .env

source .env
aws sts get-caller-identity
```

## Notes

- There are other properties in the attestation you can use in the Trust Policy.
  Namely, the subject, which is the primary key/unique identifier for the actual Google account that has authenticated.
  For simplicity these are excluded here but you can punch the token into [any JWT](https://oauth.tools) [of choice](https://jwt.io) and view them.
  **Warning: When implementing your account management system, you shouldn't use the email field in the ID token as a unique identifier for a user.
  Always use the sub field as it is unique to a Google Account even if the user changes their email address.**
- Technically I don't think the `id_token` is supposed to be used for this but hey, it works.
- By default, Step-CLI will randomize the listening port.
  This has never once played nicely for me with authorized/trusted redirect URI configurations on Oauth apps.
  This is why we fix the port number, other wise you'll just get `redirect_uri_mismatch` errors.
- There _should_ be a way to get proper PKCE authorization code flow working with GCP's Oauth.
  However the token exchange API seems to insist on a `client_secret`.
  I had a look at getting untrusted flows working via iOS/Android/TV flows but mobile has deprecated loopback listens in favor of
  whatever mobile APIs there are, so localhost redirect URIs are blocked.
  The device flow _could_ maybe work but involves entering a code into *another* webpage so seemed a big step worse.
  I haven't tried exhaustively since it's not particularly sensitive in this use case since the user still has to auth to GCP but it is poor.
- Not sure why but the env vars weren't taking for me for the `assume-role-...` call so I added the arguments directly.
  Hopefully it works nicely for you.
- There are some session duration controls on the role, set these as suits your security demands.

## Thanks

- [KCA](https://eigenmagic.net/@kca) for reviewing this

## References

- [Official AWS documentation](https://aws.amazon.com/blogs/security/access-aws-using-a-google-cloud-platform-native-workload-i)
- [AWS CLI reference](https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role-with-web-identity.html)
- [AWS CLI Environment vars](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
- [GCP Developer documenation on Oauth clients](https://developers.google.com/identity/protocols/oauth2/native-app)
- [Detailed tutorial on GCP-side setup](https://itgix.com/blog/workload-identity-federation-aws-access-from-gcp/)
- [Tutorial that explains the OIDC claims](https://www.luishelder.com/access-aws-resources-from-gcp-cloud-run-with-workload-identity/)
- [Step-CLI documentation](https://smallstep.com/docs/step-cli/reference/oauth/)
- [Local OIDC CLI tool](https://github.com/jentz/oidc-cli)

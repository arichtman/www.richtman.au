+++
title = "AWS EKS IRSA Debugging"
date = 2024-08-01T12:33:45+10:00
description = "Pragmatic guide to not go insane."
[taxonomies]
categories = [ "Technical" ]
tags = [ "aws", "eks", "k8s", "kubernetes", "auth", "oidc", "authorization", "authentication", "irsa" ]
+++

## Problem

Your EKS workload is failing to assume an AWS role.
If you need to know more about how and why this works, please consult either [the vendor's documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html),
or any of the many online articles.

## Prerequisites

- `kubectl`
- EKS cluster access
  At least to run a workload in your namespace
- AWS IAM read access

## Solution

Log into AWS, go to _IAM_ and inspect the _Identtiy Provider_.
Make sure at least one of them matches the _EKS_ cluster's _OpenID Connect provider URL_.
Note the _Provider URL_ and the _Audience_.

Log into AWS and inspect the role we're trying to assume.
The _Trust Relationship_ policy is key here.
Check the `Condition` policy element:

- The one ending in `:sub` should match your combination of _Namespace_ and _Kubernetes Service Account_.
  Syntax is `system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT_NAME`.
- The one ending in `:aud` should match the _Audience_ we noted earlier.
- The logical check should match.
  Pay attention to the mismatch of `StringEquals` with values including wildcards (`*` or `?`)
- The leading portion of the condition keys should match the _Provider URL_ we noted earlier.

Create a dummy pod.
This is to allow us to interactively examine the situation.
**Amend the following YAML with _your_ service account name!**
Don't forget to delete this pod after you're done.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: aws-repl
spec:
  containers:
  - command:
    - sleep
    - "3000"
    image: amazon/aws-cli
    name: aws-repl
  serviceAccountName: $SERVICE_ACCOUNT_NAME
```

The pod should now be running idling.
Confirm this `kubectl describe po/aws-repl`.
Then enter the REPL `kubectl exec --rm -it po/aws-repl -- /bin/bash`.
You should now see a prompt.

Interrogate the environment as you wish.

Check the pod has been mutated to have role assumption stuff.
`env | grep AWS_` should yield something like:

```shell
AWS_ROLE_ARN=arn:aws:iam::999999999999:role/eks/some-role-name
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
AWS_DEFAULT_REGION=eu-west-1
AWS_REGION=eu-west-1
AWS_STS_REGIONAL_ENDPOINTS=regional
```

Ensure `$AWS_ROLE_ARN` matches the role for the account precisely.

Check the subject of the JWT: `cat $AWS_WEB_IDENTITY_TOKEN_FILE`
You may wish to use [a cli tool](https://github.com/mike-engel/jwt-cli),
[a pure shell tool](https://gist.github.com/angelo-v/e0208a18d455e2e6ea3c40ad637aac53),
or [a web tool](https://jwt.io/).

Test assuming the role: `aws sts get-caller-identity`.

## References

- Pain

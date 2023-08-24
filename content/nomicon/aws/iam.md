# IAM

## Handy policy snippets

Apply to anyone in your organization.
Effectively auto-scaling across accounts.

```json
"Condition": {
    "StringEquals": {
        "aws:PrincipalOrgID": "o-xxxxx"
    }
}
```

Enforce accountable session names.
Pain in the ass to work under unless you've IaC or wrapper tooling.

```json
"Condition": {
    "StringLike": {
        "sts:RoleSessionName": "${aws:username}"
    }
}
```

Apply only to SSO/SAML users.
Helpful to separate bots/services/iam users from actual humans.

```json
"Condition": {
    "StringLike": {
        "saml:namequalifier": "*"
    }
}
```

Deny if tags aren't being set correctly.
The trick here is that when creating a resource it won't *have* the `resourceTag`, so we work off `requestTag` too.

```json
"Condition": {
    "StringNotLike": {
        "aws:ResourceTag/email": "foo",
        "aws:RequestTag/email": "foo"
    }
}
```

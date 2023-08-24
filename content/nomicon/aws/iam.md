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

Deny if required tags aren't present.
The trick here is that when creating a resource it won't *have* the `resourceTag`, so we work off `requestTag` too.
However, this also means any tag update requests will also have to carry the mandatory tag payload.

```json
"Statement": [
    {
      "Sid": "DenyIAMSetWrongTag",
      "Effect": "Deny",
      "Action": [
        "iam:Tag*"
      ],
      "Condition": {
        "StringNotLike": {
          "aws:ResourceTag/email": "*",
          "aws:RequestTag/email": "*"
        }
      },
      "Resource": "*"
    }
]
```

Deny removing important tags.
This will deny _any_ untag request that includes the control tag.

```json
"Statement": [
    {
      "Sid": "DenyIAMRemoveControlTag",
      "Effect": "Deny",
      "Action": [
        "iam:Untag*"
      ],
      "Condition": {
        "ForAnyValue:StringEquals": {
          "aws:TagKeys": [
            "email"
          ]
        }
      },
      "Resource": "*"
    }
]
```

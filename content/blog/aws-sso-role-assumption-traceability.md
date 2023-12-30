+++
title = "AWS SSO Role Assumption Traceability"
date = 2023-06-14T10:30:55+10:00
description = "Ensuring you can always point a finger via CloudTrail"
[taxonomies]
#categories = [ "Technical" ]
tags = [ "aws", "sso", "iam", "audit", "infosec" ]
+++

## Problem

Roles can be assumed by many users.
CloudTrail only captures the role and session name.
Users can assume roles with inconsistent or meaningless session names.
This makes audit of activity difficult.

[Just take me to the fix!](#solution)

## Analysis

This is pretty solved for by setting the trust boundary to enforce session names.
You can see the references for an AWS article about it.

However for SSO users it's a bit different.
SSO users actually assume a role when they authenticate.
That's how PermissionSets get applied.
So we're doing a nested role assumption when we want to control the session name.
We'll refer to these as the first and second roles and assumptions.

Because the first role assumption API call is sts:AssumeRoleWithSAML, certain properties are available.
These include stuff from the Identity Provider, like name, username, groups, and more.
You can check the reference section for a link.

However, in the second assumption, none of the SAML properties are available.
We have to operate only on the properties of the existing users's session.

## Solution

The `UserId` property of the session should suffice.
It's constructed of the PermissionSet Role Id from the first account, and the SAML username, colon delimited.
So in my case, it appears like this `AROAVVR3MZ54DNABOTNZD:ariel.richtman@silverrailtech.com`.
That leading role Id will change, based on which account and permissionset were used for the first assumption.
For our use case, we don't mind so much and don't want to have to maintain a list of them.
Users will have to set their session name to match their unique part of their email address.
This more-or-less matches their username and is canonical within the company, so traceable.

Trust relationship policy:

```json
{
    "Version": "2012-10-17",
    "Statement":
    [
        {
            "Sid": "AllowSSOAssumption",
            "Effect": "Allow",
            "Principal":
            {
                "AWS": "arn:aws:iam::389892853624:root"
            },
            "Action":
            [
                "sts:AssumeRole"
            ],
            "Condition":
            {
                "StringLike":
                {
                    "aws:UserId": "*:${sts:RoleSessionName}@silverrailtech.com"
                }
            }
        }
    ]
}
```

## References

- [AWS docs on session naming](https://aws.amazon.com/blogs/security/easily-control-naming-individual-iam-role-sessions/)
- [AWS IAM docs on SAML keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#condition-keys-saml)
- AWS Support (Man N.)

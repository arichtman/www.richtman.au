+++
title = "Artifactory SAML SSO Session Invalidation"
date = 2024-06-26T15:23:13+10:00
description = "For any other poor soul out there"
[taxonomies]
categories = [ "Technical" ]
tags = [ "artifactor", "auth", "saml", "authorization", "authentication" ]
+++

## Problem

Entra ID is your workforce identity (could be any SAML provider, really).
Artifactory is configured to use Entra for SSO by way of SAML.
Leaving Artifactory open for a while forces users to log in again on unrelated SSO applications.

## Solution

It seems to be the Artifactory web GUI that's trying to terminate the user's session.
Since this is an SSO session it ends for lots of unrelated applications.

Follow the vendor guide to configure the _frontend session time_ to something longer.
I went with 8 hours.

## References

- [Vendor configuration guide](https://jfrog.com/help/r/how-to-set-an-artifactory-ui-session-timeout/how-to-set-an-artifactory-ui-session-timeout)

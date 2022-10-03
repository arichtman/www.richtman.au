+++
title = "Securing a Custom Domain on Netlify"
date = 2022-08-21T06:57:13Z
[taxonomies]
categories = [ "Technical" ]
tags = ["netlify", "tls", "dns" ]
+++

## Problem

Netlify custom domain HTTP works fine but HTTP**S**/TLS throws certificate mismatch errors

## Cause

CNAME redirection to Netlify works fine, but Netlify serves certificates for `abc-xyz-slug.netlify.app` instead of your custom domain. Netlify has a service to use LetsEncrypt to give you valid certificates, but they want you to transfer your domain management to their DNS service. This was not what I wanted as the domain is used for other things and I want to keep it in Terraform/AWS for those use cases.

## Fix

Delegate a zone for the subdomain you want Netlify to securely serve on.

1. Create Netlify site
1. Add a custom domain in Netlify and specify the subdomain you wish to host at
1. Note the name servers Netlify wants you to set to transfer your domain
1. Log into your DNS hosting provider and set `NS` type record for the subdomain you wish to host at with the name server values from Netlify
1. Wait for this to propagate and Netlify's TLS should start working on your subdomain.

+++
title = "Step-CA Certificates using Kanidm Oauth2/OIDC"
description = "Swish!"
date = 2025-12-14T13:31:19+10:00
[taxonomies]
categories = [ "Technical" ]
tags = [ "oauth", "oauth2", "oidc", "kanidm", "security", "auth", "pki", "smallstep", "step-cli", "step-ca", "certificates", "trust" ]
+++

# Step-CA Certificates using Kanidm's Oauth2/OIDC

High-level:

1. Configure an Oauth2 OIDC client in Kanidm
1. Configure Kanidm as a provisioner in Step-CA
1. Verify and use

## Kanidm Oauth2 OIDC Client Setup

```bash
# Set these according to your environment
export KANIDM_FQDN=id.richtman.au
export STEP_CA_URL=https://ca.richtman.au

# Login with permissions we need
kanidm login -D idm_admin

# Create group
kanidm group create step-ca_users
# Add our user
kanidm group add-members step-ca_users "$(whoami)@${KANIDM_FQDN}"

# Public clients can't have a client secret...
kanidm system oauth2 create-public step-ca Step-CA "${STEP_CA_URL}"
kanidm system oauth2 enable-localhost-redirects step-ca

kanidm system oauth2 set-landing-url step-ca "${STEP_CA_URL}"
kanidm system oauth2 add-redirect-url step-ca http://localhost:10000

# Set the client to map the scopes we need the claims of
kanidm system oauth2 update-scope-map step-ca step-ca_users openid email

# Review and verify our configuration
kanidm system oauth2 get step-ca
```

Now we need to configure our provisioner with Step-CA.
In the `authority.provisioners` list...

```json
{
  "admins": [
    "ariel@richtman.au"
  ],
  "claims": {
    "defaultTLSCertDuration": "2h",
    "disableRenewal": true,
    "maxTLSCertDuration": "8h"
  },
  "clientID": "step-ca",
  "clientSecret": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  "configurationEndpoint": "https://${KANIDM_FQDN}/oauth2/openid/step-ca/.well-known/openid-configuration",
  "domains": [
    "${KANIDM_FQDN}"
  ],
  "listenAddress": "localhost:10000",
  "name": "kanidm",
  "scopes": [
    "openid",
    "email"
  ],
  "type": "OIDC"
}
```

Finally, we can issue certificates using our provider.

```bash

# Verify our configuration is present and correct
step ca provisioner list

# Request and have issued a certificate
step ca certificate \
  "$(whoami)@id.richtman.au" "$(whoami).crt" "$(whoami).key" \
  --provisioner kanidm
```

## Notes

- Step-CA does seem to allow me to generate certificates for arbitrary email addresses.
  This is documented as a feature of having the administrator's email.
  Since it's just me knocking about these systems I didn't verify the restiction options.
  You would be wise to do so in a multi-user scenario and I likely will when I get Kubernetes working with it.
  Presumably also one would set the system authenticating the certificate to only accept domains the
  CA is rightfully entitled to sign for.
- Kanidm refuses to provide client secrets for public clients.
  Step-CA does not explicitly support this secretless flow (see references).
  However this does work, and I can't see the `client_secret` parameter in Kanidm logs.
- You can use Kanidm users other than `idm_admin`, whatever has enough permissions.
- We don't technically need any scopes other than the `oidc` marker one, I think,
  since we're ignoring the access token entirely.

## References

- [Smallstep docs](https://smallstep.com/docs/certificate-manager/oidc/)
- [Discord message with diagram](https://discord.com/channels/837031272227930163/841249977699401759/1359553091787034765)
- [Smallstep docs note on client secret](https://smallstep.com/docs/step-ca/provisioners/#notes)

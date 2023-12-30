+++
title = "Proxmox trust with Step CLI"
description = "It's quick, easy, and free."
date = 2023-10-22T19:09:51+10:00
[taxonomies]
#categories = [ "Technical" ]
tags = [ "proxmox", "virtualization", "tls", "trust", "certificates", "x509", "step-cli" ]
+++

# Proxmox trust with Step CLI

First, create ourselves an intermediate authority with some restrictions.
You can find the template files on the post about Kubernetes with Step CLI.

```sh
step certificate create proxmox-ca pve-root-ca.pem pve-root-ca.key --ca root-ca.pem --ca-key root-ca-key.pem \
  --ca-password-file root-ca-pass.txt --insecure --no-password --template granular-dn-intermediate.tpl \
  --set-file dn-defaults.json --not-after 8760h
```

Next up we'll need a leaf node certificate for TLS.
Substitute your node name as required.

```sh
export NODE_DNS_NAME=proxmox
step certificate create proxmox-tls pve-tls.pem pve-tls.key --ca pve-root-ca.pem --ca-key pve-root-ca.key \
  --insecure --no-password --template granular-dn-leaf.tpl --set-file dn-defaults.json --not-after 2160h --bundle \
  --san "${NODE_DNS_NAME}" --san "${NODE_DNS_NAME}.local" --san localhost --san 127.0.0.1 --san ::1 --san "$(getent hosts ${NODE_DNS_NAME} | cut -f1 -d' ')"
```

Now we'll load those up on the target machine and restart the service.
**Note:** Backing up the original certificates is left up to you.

```sh
rsync ./pve-tls.pem proxmox:/etc/pve/nodes/proxmox/
rsync ./pve-tls.key proxmox:/etc/pve/nodes/proxmox/

rsync ./pve-root-ca.pem proxmox:/etc/pve/
rsync ./pve-root-ca.key proxmox:/etc/pve/priv/

ssh proxmox systemctl restart pveproxy
# Confirm the certificate is in use
curl https://${NODE_DNS_NAME}:8006
```

Finally, we will install the root CA so the Proxmox appliance will trust its own certificates.

```sh
# On the Proxmox machine
curl https://www.richtman.au/root-ca.pem -o /usr/local/share/ca-certificates/richtman-au.crt
update-ca-certificates
# We can confirm the trust
curl https://localhost:8006
```

## Notes

- Possibly a service reload would have been sufficient. YMMV if you have availability requirements.
- There seems to be a UUID for the OU, I elected not to bother preserving it.
  Similarly the CommonName and Organization have been discarded.
- Firefox sometimes requires a configuration setting to use system trust stores.
  [Instructions](https://support.mozilla.org/en-US/kb/setting-certificate-authorities-firefox)

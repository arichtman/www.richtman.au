+++
title = "Yubikey fun"
description = ""
date = 1970-01-01
draft = true
[taxonomies]
categories = [ "Technical" ]
tags = [ "yubikey", "infosec", "pgp", "security" ]
+++

# Yubikey PGP fun/setup with MacOS Monterey

## Aims

- Trust chain
- Medium-term, dedicated keys for email
- Medium-term keys stored on Yubikey
- Keys also used for sign in
- Keys also used for Git commit signing
- Keys also used for SSH?

## Method

1. Create master key with Certify only
1. Create and certify subkeys with specific capabilities
1. Encrypt and back up the master key
1. Upload subkeys to Yubikey
1. Configure SSH(?), sign in, and commit signing to use keys

### GPG

There _really_ should be a way to do this non-interactively...

```bash
gpg --full-generate-key --expert --pinentry-mode loopback

ECC custom
disable signing
10y
Ariel Richtman
ariel@richtman.au

# You should see public and secret key created and signed

gpg --list-keys && gpg --list-secret-keys
````

### Sequioa

```bash
puk=$SOME_ALPHANUMERIC_MIN_8
pin=$SOME_NUMERIC_MIN_4_MAX_8
ykman --device $id piv access change-puk --puk 12345678 --new-puk $puk
ykman --device $id piv access change-pin --pin 123456 --new-pin $pin
ykman --device $id piv access change-management-key --protect --pin $pin --force
```

sc_identities should show something from the inserted card
If nothing shows we got issues

Try enabling the gui and checking

sc_auth pairing_ui -s enable
sc_auth pairing_ui -s status

plug and unplug, no dice.

ykman --device $id piv reset --force
turns out you only have one so no need for device
ykman access info
confirms we're back to stock settings
unplug and replug
no gui
sc_auth identities - nothing
rats

## References

- [Vendor guide](https://support.yubico.com/hc/en-us/articles/360016649059-Using-Your-YubiKey-as-a-Smart-Card-in-macOS)
- [PIV reset guide](https://support.yubico.com/hc/en-us/articles/360013645480-Resetting-the-Smart-Card-PIV-Applet-on-Your-YubiKey)
- [Yubikey madness](https://felixhammerl.com/2022/08/29/yubikey-madness.html)
https://www.edmundofuentes.com/blog/2022/05/16/yubikey-gpg-ssh-macos-monterey-m1/

- [SO with fix for pinentry](https://superuser.com/questions/1676763/import-openpgp-key-on-nixos)
- [Vendor documentation](https://developers.yubico.com/PGP/)

https://rzetterberg.github.io/yubikey-gpg-nixos.html
- [NixPkgs Issue](https://github.com/NixOS/nixpkgs/issues/35464)

+++
title = "Up Bank"
description = "If we ever get decent banking APIs..."
[taxonomies]
categories = [ "Technical" ]
tags = [ "nomicon", "ideas", "api", "up-bank" ]
+++

# Up Bank

## API Wrapper/library

Good Rust practice

## Automated transfers

Can't create transactions at this time, boo.
Can't create requests for payments either, boo.
Was going to ask support about options/timelines but they're in the middle of an incident lol

- Scheduled daily transfer of X between Up accounts
- Scheduled weekly check of balance and top-up

## Reversing out whatever the app does

I suspect the app basically registers a TOTP/HOTP secret and that's how it can do more than the public API...
Definitely against ToS to do this but...

- Pull apk
- Patch probable certificate pinning
- Check for proxy avoidance
- Patch self integrity check if exists
- Deploy intercepting proxy on machine
- Mind that it doesn't report home about patched apk
- Install app and login from scratch
- Pick apart the traffic

## GraphQL layer

- Rust or Python

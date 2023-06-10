+++
title = "Pre-Commit"
description = "Ideas for Pre-Commit"
date = 1970-01-01
[taxonomies]
categories = [ "Technical" ]
tags = [ "nomicon", "ideas", "pre-commit" ]
+++

# Pre-commit

## ModuleNotFoundError

Pre-commit runs in different contexts.
These are set by the hook property _language_.
`system` assumes stuff is on $PATH.
`python` uses virtual environments.

### Python fix

1. If required, override `language` property to `python`
1. Set property `additional_dependencies` to an array of strings.

Pre-commit should now pre-install those.
PS: Mind any errors about `ruamel`, it often wants `ruamel.yaml` or `ruamel_yaml`.

### System Fix

1. Add the missing dependency and the actual hook library to your dev dependencies
1. `poetry run pre-commit`

For all the usual reasons it's not recommended to actually install this stuff to system.

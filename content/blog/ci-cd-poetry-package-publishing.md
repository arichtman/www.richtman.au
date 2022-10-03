+++
title = "CI/CD Poetry Package Publishing"
date = 2022-09-27T07:35:11Z
description = "Using environment variables to set publish endpoints"
[taxonomies]
categories = [ "Technical" ]
tags = [ "python", "poetry" ]
+++

## CI/CD Poetry Package Publishing

Poetry thinks of publishing configuration on a per-user basis.
Poetry stores user-level configuration in `$HOME/.config/pypoetry/`.
The repository information is held in _config.toml_, and the authentication information is in _auth.toml_.
When running in an automated system like CI/CD, it's inconvenient to have to mount or populate files, particularly with sensitive information like _auth.toml_.
It's possible to configure Poetry's destination repository via environment variables, this includes authentication.
The syntax is the standard, a `POETRY_` prefix, followed by an upper-case conversion with non-alphanumerics converted to underscores.
So long as the repository name matches in all points, this will work fine.
In the example below, the repository name is _gitlab_.
PS: If you know how to avoid the `--repository` on the publish command let me know!

```Bash
export POETRY_REPOSITORIES_GITLAB_URL=https://gitlab.com/api/v4/projects/1/packages/pypi
export POETRY_HTTP_BASIC_GITLAB_USERNAME=__token__
export POETRY_HTTP_BASIC_GITLAB_PASSWORD=<redacted>

poetry publish --repository gitlab
```

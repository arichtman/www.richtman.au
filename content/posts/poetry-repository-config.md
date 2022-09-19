---
title: "Poetry Repository Config"
date: 2022-09-19T07:40:22Z
draft: false
---

## Where and how to configure repositories using Poetry

This information was developed when trying to use GitLab for private packages and PyPi cache/proxy. Poetry version at time of writing was 1.2.0. Quotes are from Poetry documentation.

### Pulling

> With the exception of the implicitly configured source for PyPI named pypi, package sources are local to a project and must be configured within the project’s pyproject.toml file. This is not the same configuration used when publishing a package.

There doesn't seem to be a user-level or global setting for package sources. You must set the source in the `pyproject.toml`

`poetry source add gitlab https://gitlab.com/api/v4/projects/1/packages/pypi/simple`

pyproject.toml

```TOML
[[tool.poetry.source]]
name = "gitlab"
url = "https://gitlab.com/api/v4/projects/1/packages/pypi/simple"
default = false
secondary = false
```

Note: PIP_INDEX_URL seems to have no impact on Poetry actions here

### Publishing

> Poetry treats repositories to which you publish packages as user specific and not project specific configuration unlike package sources.

User-specific or shared can go in config, which lives at `$HOME/.config/pypoetry/config.toml`.
Authentication is similar, just living at `$HOME/.config/pypoetry/auth.toml`
Note the lack of `/simple` URN on the end as opposed to the pulling URI.

```Bash
poetry config repositories.gitlab https://gitlab.com/api/v4/projects/1/packages/pypi
poetry config http-basic.gitlab someuser somepassword
```

Project-specific repository configuration can live in `poetry.toml` in the repository,.

poetry.toml

```TOML
[repositories]
[repositories.gitlab]
url = "https://gitlab.com/api/v4/projects/1/packages/pypi"
```

If you need to authenticate (and you should), you can add the user:pass combo into the URL.
However it may be preferable to commit the file, in which case you can use environment variables or CLI arguments.
Arguments to publish are `--username` and `--password`.
Environment variable syntax is `POETRY_HTTP_BASIC_${REPOSITORY_NAME}_(USERNAME|PASSWORD)`.
In our example that would be `POETRY_HTTP_BASIC_GITLAB_USERNAME` and `POETRY_HTTP_BASIC_GITLAB_PASSWORD`

If everything is configured correctly you may publish with `poetry publish --repository gitlab [--build] [--username foo --password bar]`

Note: Pip doesn't have any publishing capability, so PIP_INDEX_URL was not tested.

### Misc

- Check your active config: `poetry config --list`
- When calling `poetry config`, _repo_ is an alias for _repositories_
- GitLab PATs can be used with either your username or `__token__` as username
- If you set `default = true` you'll completely avoid PyPi
- If you define _any_ sources in `pyproject.toml` they will be searched before PyPi
- If you want PyPi to still be the first search, set every source as `secondary = true`
- Mounting the pypoetry config directory to a container can work but mind your config doesn't clash

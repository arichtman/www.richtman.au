+++
title = "Poetry Package Development With VSCode Devcontainers"
date = 2022-09-19 18:48:23+10:00
description = "Challenges and workarounds for development containers"
[taxonomies]
categories = [ "Technical" ]
tags = [ "python", "poetry" ]
+++

Updated for Poetry 1.2.0

## Problem

You're developing a Python package in a devcontainer, you set up your `pyproject.toml` but when building the VSCode devcontainer `poetry install` fails.

```TOML
packages = [
    { include = "py_acr122u", from = "src" },
]
```

The error may look like this:

```bash
  /src/py_acr122u does not contain any element
[2022-08-28T07:26:56.367Z]
  at /usr/local/lib/python3.10/site-packages/poetry/core/masonry/utils/package_include.py:60 in check_elements
[2022-08-28T07:26:56.371Z]       56│         return any(element.suffix == ".py" for element in self.elements)
[2022-08-28T07:26:56.371Z]       57│
[2022-08-28T07:26:56.372Z]       58│     def check_elements(self):  # type: () -> PackageInclude
[2022-08-28T07:26:56.372Z]       59│         if not self._elements:
[2022-08-28T07:26:56.372Z]     → 60│             raise ValueError(
[2022-08-28T07:26:56.372Z]       61│                 "{} does not contain any element".format(self._base / self._include)
      62│             )
[2022-08-28T07:26:56.372Z]       63│
[2022-08-28T07:26:56.372Z]       64│         root = self._elements[0]
[2022-08-28T07:26:56.624Z] Error: error building at STEP "RUN pip install poetry     && poetry config virtualenvs.create false     && poetry install --no-interaction": error while running runtime: exit status 1
[2022-08-28T07:26:56.629Z] Stop (25791 ms): Run: docker build -f /home/arichtman/repos/py-acr122u/.devcontainer/Containerfile -t vsc-py-acr122u-ca0eeac3cc1a8372c4a804bf742aac10 /home/arichtman/repos/py-acr122u
```

[Just take me to the fix!](#hybrid-install-method)

## Cause

Your `pyproject.toml` file (rightly) contains a reference to a local package that's under development. This is Poetry's version of `pip install --editable`. However, the local package location is not available during container build, and devcontainers don't allow mounting things or passing arbitrary arguments to the build stage.

## Analysis

There are 3 issues here:

- Build-time lack of `pyproject.toml`
- Pip/Poetry's path for local package files
- Running in an appropriate environment

For build-time lack of project specification we have 2 options:

- Use Docker's `COPY` feature to provide the files (though static)
- Push the install further down the process using [Lifecycle Scripts](https://code.visualstudio.com/docs/remote/devcontainerjson-reference#_lifecycle-scripts)

When `pip` installs a local package, it sets a `.pth` file with the absolute path to the parent directory containing the package. This means that we **must** match the location of our source files with where they will eventually be mounted. Otherwise any attempts to use the package will result in missing file errors.

Typical workflow for poetry is to run `poetry shell` when you want to access the project's dependencies. Two approaches here:

- Configure Poetry to install directly to the operating system, eliminating the need for entering the project's virtual environments.
- Modify the shell command used in the container so that it enters the virtual environment every time.

## Fix

### Hybrid install method

As of Poetry 1.2.0 release we now have some new features that support a hybrid mode of installation.
This will allow us to re-use our cached image layers with our packages installed, but still have correct pathing for an editable install of the package under development.
If you need to authenticate during the build or at runtime, see the optional sections.

`poetry.toml`:

```TOML
[virtualenvs]
create = false
```

Dockerfile/Containerfile:

```Dockerfile
# Optional, for build time source authentication
ARG POETRY_HTTP_BASIC_GITLAB_USERNAME
ARG POETRY_HTTP_BASIC_GITLAB_PASSWORD

# Required
COPY pyproject.toml poetry.lock ./
RUN pip install poetry \
    && poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-root --no-cache --quiet --sync
```

`.devcontainer.json`:

```JSON
{
// Required
  "onCreateCommand": [
    "poetry"
    ,"install"
    ,"--no-interaction"
    ,"--no-cache"
    ,"--only-root"
    ,"--quiet"
  ],
// Optional, for build time source authentication
  "build": {
    "args": {
      "POETRY_HTTP_BASIC_GITLAB_USERNAME": "__token__"
      ,"POETRY_HTTP_BASIC_GITLAB_PASSWORD": "${localEnv:GITLAB_PRIVATE_TOKEN}"
    }
  },
// Optional, for run time source and publish authentication
  "containerEnv": {
    "POETRY_HTTP_BASIC_GITLAB_USERNAME": "__token__"
    ,"POETRY_HTTP_BASIC_GITLAB_PASSWORD": "${localEnv:GITLAB_PRIVATE_TOKEN}"
  }
}
```

Details:

We have to specify Poetry as a dependency in the `pyproject.toml` or else sync will uninstall it and our onCreateCommand to install locally will fail.
The poetry config we set in the Dockerfile doesn't persist to the onCreateCommand. So we need to set local config to avoid virtualenv creation.
We use the sync option to remove packages on the system install that aren't part of our specification, and might interfere.
Note that on some distributions with system Python the packages will install to a `dist-packages` directory instead [link](https://stackoverflow.com/questions/9387928/whats-the-difference-between-dist-packages-and-site-packages). You can simply use an `ENV` instruction to set the [PYTHONPATH variable](https://docs.python.org/3/tutorial/modules.html#the-module-search-path) to the `site-packages` location that Poetry uses (in my case it was /usr/lib/python3.9/site-packages). This _will_ leave an additional Poetry (and dependencies) install on your image though, unless you also `--target $PYTHONPATH` on your pip install.

### Using Poetry virtual environments

By setting our VSCode `settings.json` up in the container context, we're able to substitute zsh/bash/ash for our Poetry shell. We also configure our container to install our poetry environment on creation.

`devcontainer.json`:

```JSON
[
  "onCreateCommand": [
    "poetry",
    "install",
    "--no-interaction"
  ],
  "settings": {
    "terminal.integrated.defaultProfile.linux": "poetry",
    "terminal.integrated.profiles.linux": {
        "poetry": {
            "path": "/usr/local/bin/poetry",
            "args": [
              "shell"
            ]
        },
    }
  }
]
```

### Using the container directly

Amend our `Containerfile`:

- Set `WORKDIR` to match where the repo will be mounted
- Use `COPY` to add all the repository files
- Configure `poetry` to install directly to the operating system
- Install everything

```Dockerfile
WORKDIR /workspaces/py-acr122u
COPY . ./

RUN pip install poetry \
    && poetry config virtualenvs.create false \
    && poetry install --no-interaction
```

Optional but recommended:

Add a `.dockerignore` file to the context directory of the `COPY`, here we should ignore all the usual Python suspects but also the `.git` directory.

## Notes

- I'm aware that `pip install poetry` isn't preferred, however it's a devcontainer. It's ephemeral and single-purpose, so there's no need to isolate the Poetry installation from Pip et al.
- On larger size projects the build time can likely be improved by a more targetted COPY command. What's provided is a general-purpose fix.
- It feels a bit janky copying stuff into the container then mounting over it.
- Because the `COPY` instruction is not hermetic, Docker etc will rebuild from that layer every time.
- Using `virtualenvs.in-project` has caused me issues before, with clashes between container and host.
- For containers that will actually ship use of `virtualenvs.create = false` is fine and even desirable.
- It would also be possible to run `poetry shell` at the end of `.bashrc` or similar, however this would be a subshell and could be exited accidentally. Also we'd be back to `echo "run foo" >> ~/.profile`. It's just a bit icky.
- I have tried using the lifecycle scripts to run poetry shell before, it does _work_ but it's really just holding open a process that should have terminated successfully some time ago. Again, ick.

## References

- [snekcode](https://stackoverflow.com/questions/55987337/visual-studio-code-remote-containers-change-shell)

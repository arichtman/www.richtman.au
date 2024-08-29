+++
title = "GitLab and Docker Compose Tips n Tricks"
date = 2024-08-21T13:39:00+10:00
description = ""
[taxonomies]
categories = [ "Technical" ]
tags = [ "gitlab", "cicd", "ci", "ruby", "cucumber", "testing", "docker", "docker-compose" ]
+++

# GitLab and Docker Compose Tips n Tricks

## Service Chaining

Services can be configured to run to completion in sequence.

```YAML
services:
  initialise_data:
    ...
  use_data:
    ...
    depends_on:
      initialise_data:
        condition: service_completed_successfully
```

Services can also rely on other services having started up and still running.

```YAML
services:
  database:
    ...
  read_database:
    ...
    depends_on:
      database:
        condition: service_healthy
```

Services can be deemed healthy or not by arbitrary command.

```YAML
services:
  rest_api:
    ...
    healthcheck:
      test: ["CMD-SHELL", "curl -f  http://localhost:5000/health || exit 1"]
      interval: 1s
      timeout: 3s
      retries: 30
      start_period: 5s
```

## Downloading Data

`COPY` supports arbitrary HTTPS downloads!
No need to `apt install -y curl`.
If you need to authenticate (e.g. to GitLab package registry), use `user:password@web.site`.

```Dockerfile
ARG MY_USER
ARG MY_PASS

COPY https://$MY_USER:$MY_PASS@gitlab.com/some-project .
```

## Docker Image Proxy

GitLab.com proxies Docker images!
In order to maximise the cache coverage, point your registry FQDN at `gitlab.com/silverrailtech`.
If you use further down-the-tree projects it'll work but not share them.

```Dockerfile
FROM gitlab.com/silverrailtech/dependency_proxy/containers/library/alpine:latest

# Or

# Articulated for CI
ARG CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX

FROM $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/library/alpine:latest

# Or

# Articulated for CI and local override
# Can use Docker defaulting...
ARG MY_REGISTRY=docker.io
FROM $MY_REGISTRY/alpine:latest
# Or shell defaulting
ARG MY_REGISTRY
FROM ${MY_REGISTRY:-docker.io}/alpine:latest
```

For a GitLab job:

```YAML
job:
  image: $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/alpine:latest
```

[Reference](https://docs.gitlab.com/ee/user/packages/dependency_proxy)

## Secrets Management by MultiStage Build

One approach is multistage build.

```Dockerfile
# Note the alias we've added at the end
FROM docker.io/library/ruby:3.1 as builder

# Copy our install definitions in-place
COPY Gemfile.lock Gemfile /app/

RUN gem install bundler:2.3.12

# If not using containers, consider "--deploy"
RUN bundle install

FROM docker.io/library/ruby:3.1 as runner

# Reference the prior container alias in the copy, and pilfer out the installed Ruby
COPY --from=builder /usr/local/bundle /usr/local/bundle
```

## Secrets Management by BuildKit Mounts

BuildKit allows single-container builds by way of secrets mounted to disk temporarily.
These examples cover authenticating Bundler with a theoretical server at `example.com`

In the Dockerfile this happens in the `RUN` instruction.

```Dockerfile
RUN ----mount=type=secret,id=BUNDLE_EXAMPLE___COM \
    BUNDLE_EXAMPLE___COM=$(cat /run/secrets/BUNDLE_EXAMPLE___COM) bundle install
```

In the compose file, we create a top-level _secrets_ element, and use that much like we use _named volumes_.

```YAML
secrets:
  BUNDLE_EXAMPLE___COM:
    environment: BUNDLE_EXAMPLE___COM
services:
  kgb:
    build:
      context: .
      dockerfile: ./Dockerfile
      secrets:
      - BUNDLE_EXAMPLE___COM
```

## Hiding Bundle Config in CI

This leaks plaintext secrets into the CI logs and also doesn't take precedence over the already-set environment variable.
This example covers authenticating Bundler with a theoretical server at `example.com`

```Dockerfile
ARG BUNDLE_EXAMPLE___COM
ENV BUNDLE_EXAMPLE___COM=$BUNDLE_EXAMPLE___COM

RUN bundle config set --global example.com $BUNDLE_EXAMPLE___COM
````

## Compose Specification

Remove any references to a compose version.
That's deprecated now.

You can also set the project name for isolation in-file.
`name: $CUCUMBER__TEST_UNIQUE_PROJECT_NAME`

[Reference](https://docs.docker.com/compose/compose-file/04-version-and-name/)

## Compose Inline Dockerfile

Where it doesn't make sense or is uncomfortable having a separate file, just put the `Dockerfile` inline.

```YAML
services:
  small_thing:
    dockerfile_inline: |
      FROM alpine
      RUN apk add curl
      CMD curl
```

## GitLab Package Registry File Retrieval

GitLab's generic package registry can be used to store and retrieve arbitrary files.
*Note*: the header *key* varies between using a Personal Access Token or a CI Job Token.
When using a PAT set `CURL_HEADER_KEY=Private-Token`.

```YAML
services:
  with_data:
    build:
      context: ..
      args:
        CI_JOB_TOKEN: ${CI_JOB_TOKEN}
        CI_PROJECT_ID: ${CI_PROJECT_ID}
        CI_API_V4_URL: ${CI_API_V4_URL}
        CURL_HEADER_KEY: ${CURL_HEADER_KEY:-JOB-TOKEN}
      dockerfile_inline: |
        ARG CI_JOB_TOKEN
        ARG CI_PROJECT_ID
        ARG CI_API_V4_URL
        ARG ARTIFACT_URL=$${CI_API_V4_URL}/projects/$${CI_PROJECT_ID}/packages/generic

        RUN curl -LJO \
          --header "$${CURL_HEADER_KEY}: $CI_JOB_TOKEN" \
          "$${ARTIFACT_URL}/$<SOME_PATH>/$<SOME_FILE>" \
          --output-dir /data \
          --create-dirs --fail
````

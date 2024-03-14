+++
title = "Busybox RFC3339 date"
date = 2024-03-14T11:02:16+10:00
description = "Tiny but handy"
[taxonomies]
categories = [ "Technical" ]
tags = [ "linux" ]
+++

## Problem

We want RFC3339 dates out of Busybox.

## Solution

Optional `-u` to use UTC instead of localizing.

```shell
date "+%Y-%m-%dT%H:%M:%SZ%z" # -u
```

+++
title = "Dismantling Ruby Gems"
date = 2024-06-26T15:51:32+10:00
description = "Part em out, scrapper"
[taxonomies]
categories = [ "Technical" ]
tags = [ "ruby", "reversing" ]
+++

## Solution

Gems are just a set of gzipped bits, some tarred.

```bash
# Our noble ~guinea pig~ library
stat demo.gem
# Open the main thing
tar xzf demo.gem
# Note 3 internal files now exposed
ls

checksums.yaml.gz  data.tar.gz  demo.gem  metadata.gz
# Here's the code, the meat of the library
tar xzf data.tar.gz

ls lib

some_ruby.rb
library_directory

ls lib/library_directory

some_more_ruby.rb
# Here's the metadata for the packaging system
gzip --decompress checksums.yaml.gz metadata.gz

ls

checksums.yaml  data.tar.gz  demo.gem  lib  metadata
```

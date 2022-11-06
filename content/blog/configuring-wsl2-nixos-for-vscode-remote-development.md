+++
title = "Configuring WSL2 NixOS for VSCode remote development"
date = 2022-10-31T14:01:00Z
description = "An as-it-happened adventure, with code."
[taxonomies]
categories = [ "Technical" ]
tags = [ "wsl2", "nixos", "nix", "vscode", "development", "sde" ]
+++

## Problem

NixOS on WSL2 fails to run VSCode.

```bash
$ nix-shell --packages wget git --run "code ."
    this path will be fetched (0.65 MiB download, 3.32 MiB unpacked):
      /nix/store/0hw3qygjvrk6bwljd0rgcvjkl7dsl6p5-wget-1.21.3
    copying path '/nix/store/0hw3qygjvrk6bwljd0rgcvjkl7dsl6p5-wget-1.21.3' from 'https://cache.nixos.org'...
    Updating VS Code Server to version d045a5eda657f4d7b676dedbfa7aab8207f8a075
    Removing previous installation...
    Installing VS Code Server for x64 (d045a5eda657f4d7b676dedbfa7aab8207f8a075)
    Downloading: 100%
    Unpacking: 100%
    Unpacked 2453 files and folders to /home/nixos/.vscode-server/bin/d045a5eda657f4d7b676dedbfa7aab8207f8a075.
    /home/nixos/.vscode-server/bin/d045a5eda657f4d7b676dedbfa7aab8207f8a075/bin/remote-cli/code: line 12: /home/nixos/.vscode-server/bin/d045a5eda657f4d7b676dedbfa7aab8207f8a075/node: No such file or directory
```

## Analysis

Inspecting the binary indicates it's dynamically linked and we're missing libstdc++

```bash
$ ldd /home/nixos/.vscode-server/bin/d045a5eda657f4d7b676dedbfa7aab8207f8a075/node
        linux-vdso.so.1 (0x00007f6d58f63000)
        libdl.so.2 => /nix/store/v6szn6fczjbn54h7y40aj7qjijq7j6dc-glibc-2.34-210/lib/libdl.so.2 (0x00007f6d58f58000)
        libstdc++.so.6 => not found
        libm.so.6 => /nix/store/v6szn6fczjbn54h7y40aj7qjijq7j6dc-glibc-2.34-210/lib/libm.so.6 (0x00007f6d58e7f000)
        libgcc_s.so.1 => /nix/store/v6szn6fczjbn54h7y40aj7qjijq7j6dc-glibc-2.34-210/lib/libgcc_s.so.1 (0x00007f6d58e65000)
        libpthread.so.0 => /nix/store/v6szn6fczjbn54h7y40aj7qjijq7j6dc-glibc-2.34-210/lib/libpthread.so.0 (0x00007f6d58e60000)
        libc.so.6 => /nix/store/v6szn6fczjbn54h7y40aj7qjijq7j6dc-glibc-2.34-210/lib/libc.so.6 (0x00007f6d58c60000)
        /lib64/ld-linux-x86-64.so.2 => /nix/store/v6szn6fczjbn54h7y40aj7qjijq7j6dc-glibc-2.34-210/lib64/ld-linux-x86-64.so.2 (0x00007f6d58f64000)
```

My first instinct is to simply install the C++ toolchain, we'll see how this is incorrect later.
We don't have nix-locate yet so we'll run it in a temp shell.
Whew, that nix-index command takes quite some time.
I suspect NixOS does a load of disk i/o which WSL isn't known for doing well.

```bash
$ nix-shell --packages nix-index --run 'nix-index && nix-locate --top-level libstdc++.so.6 | grep gcc'
    + querying available packages
    + generating index: 55415 paths found :: 23657 paths not in binary cache :: 08452 paths in queue
    Error: fetching the file listing for store path '/nix/store/siv7varixjdfjs17i3qfrvyc072rx55j-ia-writer-duospace-20180721' failed
    Caused by: response to GET 'http://cache.nixos.org/siv7varixjdfjs17i3qfrvyc072rx55j.ls' failed to parse (response saved to /run/user/1000/file_listing.json.1)
    Caused by: expected value at line 1 column 1
    + generating index: 66016 paths found :: 23816 paths not in binary cache :: 00000 paths in queue
    + wrote index of 44,839,458 bytes
    libgccjit.out                                         0 s /nix/store/7mlq5b4622xk7754rrz20zs9m73j65p4-libgccjit-11.3.0/lib/libstdc++.so.6
    libgccjit.out                                 2,157,120 x /nix/store/7mlq5b4622xk7754rrz20zs9m73j65p4-libgccjit-11.3.0/lib/libstdc++.so.6.0.29
    libgccjit.out                                     2,498 r /nix/store/7mlq5b4622xk7754rrz20zs9m73j65p4-libgccjit-11.3.0/lib/libstdc++.so.6.0.29-gdb.py
    gcc-unwrapped.lib                                     0 s /nix/store/8mhaj6yvvb7rq0kl5xmg6wl9myxvs804-gcc-11.3.0-lib/lib/libstdc++.so.6
    gcc-unwrapped.lib                             2,157,120 x /nix/store/8mhaj6yvvb7rq0kl5xmg6wl9myxvs804-gcc-11.3.0-lib/lib/libstdc++.so.6.0.29
    gcc-unwrapped.lib                                 2,494 r /nix/store/8mhaj6yvvb7rq0kl5xmg6wl9myxvs804-gcc-11.3.0-lib/lib/libstdc++.so.6.0.29-gdb.py
```

Let's try that again with gcc installed...

```bash
$ nix-shell --packages wget git gcc --run "code ."
  /home/nixos/.vscode-server/bin/d045a5eda657f4d7b676dedbfa7aab8207f8a075/bin/remote-cli/code: line 12: /home/nixos/.vscode-server/bin/d045a5eda657f4d7b676dedbfa7aab8207f8a075/node: No such file or **directory**
```

Womp womp, at this point I do some research and find some LD_LIBRARY_PATH hacks.
There's no way I'm resorting to that on my shiny NixOS system, it's not in the spirit.
Then again, the NixOS way would be to include any and all dependencies in your NixPkg, or to statically link.
Perhaps I'll just... install VSCode?

```bash
$ nix-env --query --available vscode
    vscode-1.69.2
```

Bingo! We'll add it to our system packages and we should be good to go.
`$ sudo nano /etc/nixos/configuration.nix`

```Nix
{
  environment.systemPackages = with pkgs; [
    git wget vscode
  ];
}
```

Now a rebuild with switch and voil...aah?

```bash
$ sudo nixos-rebuild switch
$ code .
    To use Visual Studio Code with the Windows Subsystem for Linux, please install Visual Studio Code in Windows and uninstall the Linux version in WSL. You can then use the `code` command in a WSL terminal just as you would in a normal command prompt.
    Do you want to continue anyway? [y/N] y
    To no longer see this prompt, start Visual Studio Code with the environment variable DONT_PROMPT_WSL_INSTALL defined.
```

So turns out that package is _actually_ VSCode, like the client.
Who would have thought MS `wget`ing random, unmanaged tarballs that rely on Node would ever have issues...
I had another rummage around the internet but decided against installing the same node version explicitly.

## Solution

Thankfully someone has packaged a service that resolves this.
We'll need to update our `configuration.nix`, rebuild, and enable the service.

```Nix
{
  imports = [
    (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master")
  ];

  services.vscode-server.enable = true;
}
```

```bash
sudo nixos-rebuild switch
systemctl --user enable auto-fix-vscode-server.service
# Ignore the warning
systemctl --user start auto-fix-vscode-server.service
code .
```

## References

- [nixos-vscode-server](https://github.com/msteen/nixos-vscode-server)
- [Locating which package provides](https://discourse.nixos.org/t/what-package-provides-libstdc-so-6/18707/3)
- [Suggestion to install NodeJs](https://www.reddit.com/r/NixOS/comments/ivzrm2/trying_to_get_vscode_to_work_remotely_on_a_nixos/)

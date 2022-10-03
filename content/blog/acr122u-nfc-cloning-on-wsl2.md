+++
title = "Acr122u NFC Cloning on WSL2"
date = 2022-08-28T11:31:43Z
description = "Instructions on cloning MiFare classic variety cards"
[taxonomies]
categories = [ "Technical" ]
tags = [ "nfc", "acr122u", "wsl2" ]
+++

## Acr122u NFC Cloning on WSL

Presented here are my notes from cracking, dumping, and cloning a MiFare Classic 1k. No responsibility is assumed or implied, consult these entirely at your own risk. I encourage you to stay within the law with this knowledge. I also caution that this makes enough changes to the Linux system that you may want a fresh install afterwards.

Requirements:

- Windows 10+ (untested on Windows 11)
- WSL2
- Ubuntu 20.04
- ACR122U
- MiFare Classic 1k gen 1 FUID block 0 rewritable tags
- Patience

Package requirements:

- curl

## Process

1. Setup
  1. Install usb passthrough on Windows
  1. Install reader drivers from manufacturer
  1. Blacklist kernel drivers for the chipset
  1. [Setup for writing tags]
  1. Reboot system
1. Copying
  1. Read and dump source and target
  1. Write from source dump to target

## Setup

### WSL2 USB Passthrough/attach

#### Setup

Windows: `winget install usbipd`

WSL2:

```
sudo apt install linux-tools-virtual hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip `ls /usr/lib/linux-tools/*/usbip | tail -n1` 20
```

#### Use

Procedure:

1. Plug in reader
1. Attach in windows `usbipd wsl list; usbipd wsl attach --busid #-##`

References:

- [Microsoft](https://docs.microsoft.com/en-us/windows/wsl/connect-usb)

### Drivers for ACR122U

```
# Without user-agent cloudflare 403s you. this agent string isn't anything specific or magic it just has to be present
curl -L http://www.acs.com.hk/download-driver-unified/11929/ACS-Unified-PKG-Lnx-118-P.zip -H 'User-Agent: curl' -o driver.zip
unzip driver.zip
cd driver.zip
cd ubuntu
cd bionic
sudo dpkg -i libacsccid1_1.1.8-1~ubuntu18.04.1_*amd64.deb

# blacklist kernel nfc driver
echo "install nfc /bin/false" | sudo tee -a /etc/modprobe.d/blacklist.conf
echo "install pn533 /bin/false" | sudo tee -a /etc/modprobe.d/blacklist.conf
```

Now switch back to windows and reboot the system `wsl --shutdown`

Being _completely_ sure the module isn't there because of the amount of head-scratching it causes.

```
lsmod

modprobe -r pn533_usb
modprobe -r pn533
modprobe -r nfc

lsmod
```

### PCSCD

Package requirements:

- pcscd
- pcscd-tools

Service style: `sudo service pcscd start && pcsc_scan`
Manual style: `sudo pcscd -f` then in new process/window `pcsc_scan`

Note: the pcscd service may need a restart if the device is reattached, I've not tested this thoroughly.

References:

- [James Ridgway](https://www.jamesridgway.co.uk/install-acr122u-drivers-on-linux-mint-and-kubuntu/)

### Setup for writing tags

Package requirements:

- libnfc-bin: for `nfc-list` and `nfc-mfclassic`
- libnfc-examples
- autoconf, libtool: for compiling libnfc v1.8.0

Compile and install newer libnfc
```
curl -LO https://github.com/nfc-tools/libnfc/releases/download/libnfc-1.8.0/libnfc-1.8.0.tar.bz2
tar -jxf libnfc-*.bz2
cd libnfc-*

#region Commands from post
# Note: I think I had to sudo the configure call
export CFLAGS="-Wall -g -O2 -Wextra -pipe -funsigned-char -fstrict-aliasing \
      -Wchar-subscripts -Wundef -Wshadow -Wcast-align -Wwrite-strings -Wunused \
      -Wuninitialized -Wpointer-arith -Wredundant-decls -Winline -Wformat \
      -Wformat-security -Wswitch-enum -Winit-self -Wmissing-include-dirs \
      -Wmissing-prototypes -Wstrict-prototypes -Wold-style-definition \
      -Wbad-function-cast -Wnested-externs -Wmissing-declarations"

autoreconf -Wall -vis
./configure --prefix=/usr --sysconfdir=/etc
sudo make clean
sudo make
sudo make install
#endregion

# This now says using v1.8.0
sudo nfc-list
```

References:

- [Stack overflow](https://stackoverflow.com/questions/57762831/acr122-nfc-reader-does-not-work-with-libnfc-ubuntu)

## Copying

### Dumping tags

Package requirements:

- mfoc

Note: `mfoc` can sometimes leave the reader in a state where it can't be reused again. Unplugging, replugging, and reattaching it seems to restore it. I suspect it's the power cycle resetting the device's state but I should try detaching and reattaching instead of wearing my USB ports.

```
# Download the largest keys file
curl -LO https://raw.githubusercontent.com/ikarus23/MifareClassicTool/master/Mifare%20Classic%20Tool/app/src/main/assets/key-files/extended-std.keys
# Brute force using keys
sudo mfoc -f extended-std.keys -P 500 -O urmet.dmp
```

References:

- [Stephane Bounmy](https://sbounmy.com/mfclassic-urmet-tag/)

#### Lazy Cracker

This wraps `mfoc` but also sets up some crypto and nested attacks. I suspect that if your key isn't in the extended list of MCT this or `mfcuk` would be required to retrieve the keys.

```
# maybe sudo?
./miLazyCrackerFreshInstall.sh
# fresh attach
sudo miLazyCracker
```
Note: The command to flash at the very end isn't correct so it bombs but the dump left intact.

References:

- [miLazyCracker](https://github.com/nfc-tools/miLazyCracker)

#### MFCUK

Note: I was never able to get a full retrieval using this tool though I didn't let it run for more than 30 minutes. `mfcuk` was quite finnicky, without messing with the timings and telling it to use key A only it appeared to hang indefinitely, even at verbosity 3. Sometimes it seemed to work after killing and immediately relaunching. Without setting the timeouts it fails to connect entirely.

Package requirements:

- mfcuk

Recover keys: `sudo mfcuk -C -R 0:A -s 250 -S 250 # -v 3`

References:

- [Linus Karlsson](https://linuskarlsson.se/blog/acr122u-mfcuk-and-mfoc-cracking-mifare-classic-on-arch-linux/)

### Writing tags

I wasn't able to get any variant of `nfc-mfclassic W a [$UID] urmet.dmp clone.dmp [f]` working fully.
Even when it flashed the dump successfully it would not update the UID or Block 0.
However libnfc-examples came to the rescue with a dedicated function.
Note that this setuid tool can recover "bricked" tags as it will just blindly send the codes.

```Bash
sudo apt-get install libnfc-examples
sudo nfc-mfsetuid $UID wrote the UID correctly
```

### Beating Urmet

Unfortunately, Urmet are across Gen 1/FUID tags
Even with the UID cloned the reader seems to set the UID to `0a000a00` without updating the BCC.
It's unclear whether it's checking for magic packet ack or just spamming the write codes.
Either way looks like FUID/gen 1 tags won't work here.
The tags can still be recovered using the setuid tool, but they're esssentially useless for my application.

In the end I ordered Gen 2/CUID type tags.
Using the MiFare Classic Android application I tried the _Clone UID_ function.
This wrote UID and BCC correctly but the tag still wouldn't work with the reader.
This means it is defending with more than magic packet protection.
I dump the copied tag in MCT and diff them dumps:

- Manufacturer info is different
  NXP tools immediately identified the clone as a clone
  Original is marked by NXP manufacturer (leading 0x04) as mifare classic ev1 (MF1S50)
- ATQA same as original (0x400)
- ID is correct as is BCC
- Keys are different (fixable)
- Access conditions are different (can be fixed)
- SAK doesn't match (original 0x88, clone 0x08)
- Still no data stored on either tag

If Urmet are really dedicated, they could use the encryption keys to check access conditions and wallet/purse functions working during authentication.
SAK/ATQA checks seem to be entirely up to the reader manufacturer, Urmet don't publish much technical information so we'll pray those aren't a factor either.
Next step then is to copy both UID/BCC and manufacturer info, as well as the rest of the card data.

I tried writing all blocks from the dump file, it worked but sector 0 wasn't updated correctly.
In the end I copied block 0 sector 0 from the dump and wrote it using the manual/direct write feature.
This set the manufacturer info as well as UID/BCC, and the tag now works.

I may look into using the ACR122U to directly write block 0 in a future post.

References:

- [Lab401](https://lab401.com/blogs/academy/know-your-magic-cards)

## Reference

### Driver compilation

Here are some possible required packages but I think they were for compiling the driver itself, which is uneccesary if the provided deb works

```
# Same caveats here about needing any user-agent.
curl -L http://www.acs.com.hk/download-driver-unified/12030/ACS-Unified-Driver-Lnx-Mac-118-P.zip -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/53 7.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36' -o driver.zip

sudo apt install -y pkg-config
sudo apt install -y libusb-dev
sudo apt install libusb-1.0-0-dev -y
```

## Possible fixes for libnfc installation 

The ./configure install skipped some drivers with its default configuration, I can't recall if we had to do this for it to work or what.

```
Selected drivers:
   pcsc............. no
   acr122_pcsc...... no
   acr122_usb....... yes
   acr122s.......... yes
   arygon........... yes
   pn53x_usb........ yes
   pn532_uart....... yes
   pn532_spi.......  yes
   pn532_i2c........ yes
   pn71xx........... no
```

Yanked this from source code

```
  --with-drivers=DRIVERS  Use a custom driver set, where DRIVERS is a
                          coma-separated list of drivers to build support for.
                          Available drivers are: 'acr122_pcsc', 'acr122_usb',
                          'acr122s', 'arygon', 'pcsc', 'pn532_i2c',
                          'pn532_spi', 'pn532_uart', 'pn53x_usb' and 'pn71xx'.
                          Default drivers set is
                          'acr122_usb,acr122s,arygon,pn532_i2c,pn532_spi,pn532_uart,pn53x_usb'.
```

Threads suggested: `./configure --prefix=/usr --sysconfdir=/etc --with-drivers=acr122_pcsc,acr122_usb,acr122s,arygon`
I also tried: `./configure --prefix=/usr --sysconfdir=/etc --with-drivers=acr122_pcsc,acr122_usb,acr122s,arygon,pcsc`

I'm not sure how to use pcsc for nfc-mfclassic communication, perhaps we never needed libnfc v1.8.0 for pcscd as it was working already.

References:

- [GitHub issue](https://github.com/nfc-tools/libnfc/issues/535#issuecomment-705875449)

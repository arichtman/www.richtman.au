---
title: "Acr122u NFC Cloning on WSL2"
date: 2022-08-28T11:31:43Z
draft: true
---

## Acr122u NFC Cloning on WSL

Presented here are my notes from cracking, dumping, and cloning a MiFare Classic 1k. No responsibility is assumed or implied, consult these entirely at your own risk. I encourage you to stay within the law with this knowledge. I also caution that this makes enough changes to the Linux system that you may want a fresh install afterwards.

Requirements:

- Windows 10+ (untested on Windows 11)
- WSL2
- Ubuntu 20.04
- ACR122U
- MiFare Classic 1k gen 1 CUID block 0 rewritable tags
- Patience

Package requirements:

- curl

## Process

1. Setup
  1. Install usb passthrough on Windows
  1. Install reader drivers from manufacturer
  1. Blacklist kernel drivers for the chipset
  1. [Setup for writing cards]
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

### Setup for writing cards

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

### Dumping cards

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

### Writing cards

** Under development **

```
# Write fully unlocked to the card
# for some reason the UID is completely wrong?
sudo nfc-mfclassic W a urmet.dmp clone.dmp

# When specifying the UID it yields
Error: no tag was found or Error opening NFC reader
sudo nfc-mfclassic W a UBD5D37F2 urmet.dmp clone.dmp
# adding force yield only no tag found
sudo nfc-mfclassic W a UBD5D37F2 urmet.dmp clone.dmp f
```

# I was able to flash using nfc-mfclassic W but the UID isn't updated even tho it's the 4-bit supported one
# I wasn't able to get nfc-mfclassic working with U$UID but...
sudo apt-get install libnfc-examples
sudo nfc-mfsetuid $UID wrote the UID correctly
Mifare classic app detects the UID as same as my FOB
I tested the clone on the elevator and it's not working
Looks like the sensor is writing bad UID/BCC combo onto the card as security
I'm unable to read because of the check fail but nfc-mfsetuid can correct the issue
```
WARNING: BCC check failed!
Sent bits:     93  70  0a  00  0a  00  0a  14  49
Received bits: 08  b6  dd

Found tag with
 UID: 0a000a00
ATQA: 760a
 SAK: 08
```

I bet it writes that same UID every time. So the question, is it detecting that it's a clone OR does it just spam those magic bits at everything anyway as defence.
Spamming literally every transaction with rewrite sequences seems like overkill.
I dump the card with repaired UID in MCT and diff
- Manufacturer info is wrong
- Keys are different (though this may not be fixable)
- Access conditions are different
- Still no data stored on either card

Lets see what nxp tools says between manufacturer infos
- Immediately identified as a clone, original is marked by nxp manufacturer (leading 0x04) as mifare classic ev1 (MF1S50)
- SAK 0x08 is marked as error, original has 0x88
- ATQA 0x0400 - same as original
- ID is correct as is BCC 0x25
- Manufacturer data 0x 46 59 25 58 49 10 23 02 - total rubbish I think, original 0x C8 47 00 20 00 00 00 17, TSMC rev c8 w47 2017. Interesting...

Apparently SAK and ATQA sensitivity is up to the card reader programmer. Urmet don't publish much technical information.

TODO: dump the now fully cloned card and diff against the dump of my original FOB
TODO: look into SAK errors and what they could mean
TODO: clone manufacturer info fully and try again
TODO: Try Gen 2 One-Time-Write (OTW) stickers (ordered)
TODO: Clear out my Ubuntu install and re-visit all steps to test this documentation

References:

- [Lab401](https://lab401.com/blogs/academy/know-your-magic-cards)

## Reference

### Source tag block 0

```
BD5D37F225880400C847002000000017
01000000000000000000000000000000
00000000000000000000000000000000
8829DA9DAF767F0788008829DA9DAF76
```

All the other blocks are zeroed out with the same trailing line (i.e. same keys and access conditions).

UID: 0xBD5D37F2
BCC: 0x25

### pcsc_scan of source fob

```
 Reader 0: ACS ACR122U 00 00
  Event number: 10
  Card state: Card inserted,
  ATR: 3B 8F 80 01 80 4F 0C A0 00 00 03 06 03 00 01 00 00 00 00 6A

ATR: 3B 8F 80 01 80 4F 0C A0 00 00 03 06 03 00 01 00 00 00 00 6A
+ TS = 3B --> Direct Convention
+ T0 = 8F, Y(1): 1000, K: 15 (historical bytes)
  TD(1) = 80 --> Y(i+1) = 1000, Protocol T = 0
-----
  TD(2) = 01 --> Y(i+1) = 0000, Protocol T = 1
-----
+ Historical bytes: 80 4F 0C A0 00 00 03 06 03 00 01 00 00 00 00
  Category indicator byte: 80 (compact TLV data object)
    Tag: 4, len: F (initial access data)
      Initial access data: 0C A0 00 00 03 06 03 00 01 00 00 00 00
+ TCK = 6A (correct checksum)

Possibly identified card (using /usr/share/pcsc/smartcard_list.txt):
3B 8F 80 01 80 4F 0C A0 00 00 03 06 03 00 01 00 00 00 00 6A
3B 8F 80 01 80 4F 0C A0 00 00 03 06 .. 00 01 00 00 00 00 ..
        MIFARE Classic 1K (as per PCSC std part3)
3B 8F 80 01 80 4F 0C A0 00 00 03 06 03 00 01 00 00 00 00 6A
3B 8F 80 01 80 4F 0C A0 00 00 03 06 03 .. .. 00 00 00 00 ..
        RFID - ISO 14443 Type A Part 3 (as per PCSC std part3)
3B 8F 80 01 80 4F 0C A0 00 00 03 06 03 00 01 00 00 00 00 6A
        NXP/Philips MIFARE Classic 1K (as per PCSC std part3)
        http://www.nxp.com/#/pip/pip=[pfp=41863]|pp=[t=pfp,i=41863]
        Oyster card - Transport for London (first-gen)
        https://en.wikipedia.org/wiki/Oyster_card
        ACOS5/1k Mirfare
        vivotech ViVOcard Contactless Test Card
        Bangkok BTS Sky SmartPass
        Mifare Classic 1K (block 0 re-writeable)
```

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

+++
title = "LFCS Notes"
description = "Personal notes"
draft = true
[taxonomies]
categories = [ "Technical" ]
tags = [ "linux", "certification" ]
+++

```
# Initialize database
sudo mandb
# Search descriptions of man pages
apropos $SEARCH_TERM --section 1,5,8
```

```
find . -cmin -100 -mmin -5 -amin -1 -perm -g=w
grep -icw man
./script 2> errors.txt
sudo systemctl set-default|isolate graphical.target|multi-user.target
```
need to learn about sticky bit and chmod +t
suid works on files and execution assumes user/owner permissions, chmod 4xxx
sgid works on directories chmod 2xxx

sticky bit prevents deletion, only user/owner and root can delete
chmod +t or chmod 1xxx

service masking blocks service starting or enablement,
useful for services that are dynamically started by other services e.g. as a runtime dependency

systemctl edit --full sshd.service
systemctl revert sshd.service

systemd-cat -t $APP_NAME -p alert|info|warning|err|crit

systemctl daemon-reload # Picks up changes to unit files/startup DAG

# Handy for examples
/lib/systemd/system/$SERVICE_FILES

niceness range -20 -> 19, lower is higher priority.
nice -n $VALUE $COMMAND
renice $VALUE $PID # need root to make lower, sending higher OK by nonpriv users

ps l # shows nice
ps f # shows forks
ps ax # shows all
ps u # user-centric view
pgrep

kill -L
pgrep -a $NAME
pkill -KILL $NAME # Can omit SIG prefix

lsof -p $PID

# Find last user logins
last
lastlog

journalctl \
  $(which sudo) \ # specifci program
  -p info \ # level
  -g '^b' \ # grep
  -S 13:00 \ # since
  -U '2024-12-30 14:01:15' \ # until
  -b 0 \ for this boot


need to learn basic Vim
anacron?
cron expressions
dpkg vs apt vs ??
gpasswd??
fucking squid config

sysctl -p /etc/sysctl.d/$FILE.conf
/etc/sysctl.conf

# SELinux

seinfo -u|r|t
semanage
semanage boolean --list
semanage port --list
setsebool $OPTION 1
getsebool $OPTION
sestatus
selinux-activate
audit2why --all
audit2allow --all -M mymodule
semodule -i mymodule.pp
chcon -u unconfined_u  -r object_r -t user_home_t $FILE
chcon  --reference=$FILE
restorecon -F -R $PATH
semanage fcontext --add --type $TYPE "$PATH(/.*)?"
semanage fcontext --list
avc = access vector cache
getenforce/setenforce
/etc/selinux/config

grub security=selinux

# VMs

virt-manager

virsh define
virsh destroy # force shutdown
virsh autostart
virsh dominfo
virsh setvcpus $NAME 2 --config [--maximum]
qemu-img resize

# limits

/etc/security/limits.conf
ulimit -a
visudo

$user|%$group $host|ALL=ALL|($runas_user1,$runas_user2:[$runas_group1,$runas_group2]) [NOPASSWD:ALL] $command1, $command2

sudo -i requires user's password
su -l requires root's password

# Networking

netplan try

## Disks and volumes

mkfs.xfs|ext4
tune2fs|xfs_admin
swapon|swapoff|mkswap
dd if=/dev/0 --block=1M --count=256 status=progress of=/some/swapfile
findmnt -t xfs,ext4

/etc/fstab
$SOURCE_VOLUME $DESTINATION_PATH $FILESYSTEM_TYPE $MOUNT_OPTIONS $DUMP(can be zero) $ERROR_SCANNING
destination is "none" for swap
error scanning
0 - never
1 - priority scan
2 - secondary scan (after priority)

### NFS

#### Server

nfs-kernel-server
exportfs -r
exportfs -v
/etc/exports

$SOURCE_PATH $CLIENT_IDENTIFIER_1($OPTIONS_1) [$CLIENT_IDENTIFIER($OPTIONS_2)]
client identifier can be hosname(with wildcards), ip, or cidr
rw|ro
sync|async
no_subtree_check
no_root_squash maps client roots to "nobody" local user

#### Client

nfs-common
mount $IDENTIFIER:$PATH $PATH

### NBD

#### Server

nbd-server
/etc/nbd-server/config

allowlist = true <- actually means let clients list available block devices

[$EXPORT_NAME]
  exportname=$SOURCE_VOLUME (?path?)

#### Client

nbd-client
modprobe nbd
/etc/modules-load.d/modules.conf

nbd-client-l $IDENTIFIER
nbd-client $IDENTIFIER -N $EXPORT_NAME
nbd-client -d /dev/nbd0

### LVM

lvm2

physical volume - entire disk or partition
volume group
logical volume
physical extent

lvmdiskscan
pvcreate
pvs
vgcreate $NAME $PV [$PV]
pvcreate|pvremove
vgextend|vgreduce
lvcreate
lvs
lvresize [--resizefs]

/dev/$VG_NAME/$LV_NAME

### Storage monitoring

sysstat

iostat -h -d #device only
iostat -p all|sda
pidstat --human -d #device only
dmsetup info /dev/dm-0

stress comes from either velocity or volume
high tps = high volume, high kbps = high velocity

### Advanced permissions

setfacl --modify --recursive user|group:$USERNAME:rw|--- $PATH
setfacl --remove|remove-all
getfacl $PATH

mask is maximum permissions

chattr +a $PATH #allow append only
chattr +i $PATH #immutable
lsattr $PATH

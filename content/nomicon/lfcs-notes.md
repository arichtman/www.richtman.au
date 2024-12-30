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
need to learn about sticky bit and chmod +t??
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

sysctl -p /etc/sysctl.d/$FILE.conf
/etc/sysctl.conf

semanage
sestatus
selinux-activate
getenforce

grub security=selinux

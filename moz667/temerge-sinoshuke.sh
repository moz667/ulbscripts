#!/bin/bash
# cogido de : http://gentoo-wiki.com/TIP_Speeding_up_portage_with_tmpfs
# 
MEMSIZE=1500M
mounted=false
 
. /etc/init.d/functions.sh
 
mounttmpfs() {
     mount -t tmpfs tmpfs -o size=$MEMSIZE /var/tmp/portage
     mounted="true"
}

compile() {
     einfo "emerging ${*}"
          emerge ${*}
}

unmount() {
     ebegin "unmounting tmpfs"
          umount -f /var/tmp/portage
     eend $?
}

ebegin "Mounting $MEMSIZE of memory to /var/tmp/portage"
if [ -z "$(mount | grep /var/tmp/portage)" ]
then
     mounttmpfs
else
     eerror "tmpfs already mounted!"
     exit 0
fi
eend $?

compile ${*}
 
if [ -n "$mounted" ]
then
     unmount
fi

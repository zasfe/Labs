#!/usr/bin/env bash
LANG=C

MOUNT_POINT=`df -Ph | egrep "^\/.*rootfs$" | awk '{print$1}'`;

if test -z "${MOUNT_POINT}" 
then
    echo "# Not Find Mount point"
else
    echo "# Umount Mount point :${MOUNT_POINT} "
    umount -f ${MOUNT_POINT}
fi

test -d ./rootfs && rm -rf ./rootfs
test -d ./unsquashfs && rm -rf ./unsquashfs

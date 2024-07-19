#!/usr/bin/env bash
LANG=C

umount -f `df -Ph | egrep "^\/.*rootfs$" | awk '{print$1}'`
test -d ./rootfs && rm -rf ./rootfs
test -d ./unsquashfs && rm -rf ./unsquashfs

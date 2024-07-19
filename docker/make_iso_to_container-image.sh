#!/usr/bin/env bash
LANG=C

# prepare
ISO_URL="https://releases.ubuntu.com/18.04.6/ubuntu-18.04.6-live-server-amd64.iso";

# STEP1 ::: download iso file, read only filesystem tools
ISO_FILE=`echo ${ISO_URL} | awk -F "/" '{print $NF}'`;
ISO_OS_NAME=`echo ${ISO_FILE} | awk -F "-" '{print $1"-"$2}'`;

wget -O ${ISO_FILE} ${ISO_URL};
apt-get install -y squashfs-tools;

# step2 ::: iso mount
mkdir -p rootfs unsquashfs;
test -f ${ISO_FILE} && mount -o loop ${ISO_FILE} rootfs;

find . -type f | grep 'filesystem\.squashfs$';
#sudo unsquashfs -f -d unsquashfs/ rootfs/casper/filesystem.squashfs

ISO_ROOTFS=`find . -type f | grep 'filesystem\.squashfs$'`;
test -f ${ISO_ROOTFS} && unsquashfs -f -d unsquashfs/ ${ISO_ROOTFS};

# step3 ::: make container images
tar -C unsquashfs -c . | docker import - zasfe/${ISO_OS_NAME}

# step4 ::: container running test
docker run -it --rm -h myos -t zasfe/${ISO_OS_NAME} bash

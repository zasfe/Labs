#!/usr/bin/env bash
LANG=C

echo "# prepare";
ISO_URL="https://releases.ubuntu.com/18.04.6/ubuntu-18.04.6-live-server-amd64.iso";

echo "# STEP1 ::: download iso file, read only filesystem tools";
ISO_FILE=`echo ${ISO_URL} | awk -F "/" '{print $NF}'`;
ISO_OS_NAME=`echo ${ISO_FILE} | awk -F "-" '{print $1"-"$2}' | awk '{print tolower($0)}'`;
ISO_OS_VERSION=`echo ${ISO_FILE} | awk -F "-" '{print $1"-"$2}' | awk '{print tolower($0)}'`;

wget -O ${ISO_FILE} ${ISO_URL};
apt-get install -y squashfs-tools;

echo "# STEP2 ::: iso mount";
mkdir -p rootfs unsquashfs;
test -f ${ISO_FILE} && mount -o loop ${ISO_FILE} rootfs;

find . -type f | grep 'filesystem\.squashfs$';
#sudo unsquashfs -f -d unsquashfs/ rootfs/casper/filesystem.squashfs

ISO_ROOTFS=`find . -type f | grep 'filesystem\.squashfs$'`;
test -f ${ISO_ROOTFS} && unsquashfs -f -d unsquashfs/ ${ISO_ROOTFS};

echo "# STEP3 ::: make container images";
tar -C unsquashfs -c . | docker import - zasfe/${ISO_OS_NAME}:latest

echo "# STEP4 ::: container running test";
docker exec --rm -h myos -t zasfe/${ISO_OS_NAME}:latest cat /etc/os-release | grep -i PRETTY_NAME
echo "docker run -it --rm -h myos -t zasfe/${ISO_OS_NAME}:latest bash"


echo "# STEP5 ::: container image push";
echo "ex)";
echo " - (local only) docker image name : zasfe/${ISO_OS_NAME}";
echo " - (remote only) docker image name : zasfe/ubuntu:18.04.6-live-server-amd64.iso";
echo "";
echo "docker tag zasfe/ubuntu-18.04.6:latest zasfe/ubuntu:18.04.6-live-server-amd64.iso";
echo "docker push zasfe/ubuntu:18.04.6-live-server-amd64.iso";
echo "";

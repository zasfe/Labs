#!/usr/bin/env bash
LANG=C

echo -e "\033[34m  ## prepare \033[0m";
ISO_URL="https://releases.ubuntu.com/18.04.6/ubuntu-18.04.6-live-server-amd64.iso";

echo -e "\033[34m  ## STEP1 ::: download iso file, read only filesystem tools \033[0m";
ISO_FILE=`echo ${ISO_URL} | awk -F "/" '{print $NF}'`;
ISO_OS_VERSION=`echo ${ISO_FILE} | awk -F "-" '{print $1"-"$2}' | awk '{print tolower($0)}'`;
ISO_OS_NAME=`echo ${ISO_FILE} | awk -F "-" '{print $1}' | awk '{print tolower($0)}'`;
delimiter="-"

# 첫 번째 구분자 위치 찾기
position=$(expr index "$ISO_FILE" "$delimiter");

# 구분자 이후 문자열 출력
ISO_VERSION=${input:$position};

wget -O ${ISO_FILE} ${ISO_URL};
apt-get install -y squashfs-tools;

echo -e "\033[34m  ## STEP2 ::: iso mount \033[0m";
mkdir -p rootfs unsquashfs;
test -f ${ISO_FILE} && mount -o loop ${ISO_FILE} rootfs;

find . -type f | grep 'filesystem\.squashfs$';
#sudo unsquashfs -f -d unsquashfs/ rootfs/casper/filesystem.squashfs

ISO_ROOTFS=`find . -type f | grep 'filesystem\.squashfs$'`;
test -f ${ISO_ROOTFS} && unsquashfs -f -d unsquashfs/ ${ISO_ROOTFS};

echo -e "\033[34m  ## STEP3 ::: make container images \033[0m";
tar -C unsquashfs -c . | docker import - zasfe/${ISO_OS_VERSION}:latest

echo -e "\033[34m  ## STEP4 ::: container running test \033[0m";
docker exec --rm -h myos -t zasfe/${ISO_OS_VERSION}:latest cat /etc/os-release | grep -i PRETTY_NAME
echo -e "\033[35m  docker run -it --rm -h myos -t zasfe/${ISO_OS_VERSION}:latest bash  \033[0m";


echo -e "\033[34m  ## STEP5 ::: container image push \033[0m";
echo "ex)";
echo " - (local only) docker image name : zasfe/${ISO_OS_VERSION}:latest ";
echo " - (remote only) docker image name : zasfe/${ISO_OS_NAME}:${ISO_VERSION}";
echo "";
echo -e "\033[35m  docker tag zasfe/${ISO_OS_VERSION}:latest zasfe/${ISO_OS_NAME}:${ISO_VERSION} \033[0m";
echo -e "\033[35m  docker push zasfe/${ISO_OS_NAME}:${ISO_VERSION} \033[0m";
echo "";

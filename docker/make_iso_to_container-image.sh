#!/usr/bin/env bash
LANG=C

ISO_URL="https://releases.ubuntu.com/18.04.6/ubuntu-18.04.6-live-server-amd64.iso";

echo -e "\033[34m  ## STEP 1 ::: download iso file, read only filesystem tools \033[0m";
ISO_FILE=`echo ${ISO_URL} | awk -F "/" '{print $NF}'`;
ISO_FILE_OS_NAME_VERSION=`echo ${ISO_FILE} | awk -F "-" '{print $1"-"$2}' | awk '{print tolower($0)}'`;
ISO_FILE_OS_NAME=`echo ${ISO_FILE} | awk -F "-" '{print $1}' | awk '{print tolower($0)}'`;
delimiter="-"
# 첫 번째 구분자 위치 찾기
position=$(expr index "${ISO_FILE}" "$delimiter");
# 구분자 이후 문자열 출력
ISO_FILE_VERSION=${ISO_FILE:$position};


# example value
# ISO_FILE : ubuntu-18.04.6-live-server-amd64.iso
# ISO_FILE_OS_NAME_VERSION : ubuntu-18.04.6
# ISO_FILE_OS_NAME : ubuntu
# ISO_FILE_VERSION : 18.04.6-live-server-amd64.iso


wget -O ${ISO_FILE} ${ISO_URL};
apt-get install -y squashfs-tools;

echo -e "\033[34m  ## STEP 2 ::: iso find rootfs \033[0m";
mkdir -p rootfs
test -f ${ISO_FILE} && mount -o loop ${ISO_FILE} rootfs;


echo -e "\033[34m  ## STEP 3 ::: get rootfs and contaner make test \033[0m";
find . -type f | grep "\./rootfs" | grep -i '\.squashfs$' ;
#sudo unsquashfs -f -d unsquashfs/ rootfs/casper/filesystem.squashfs

find . -type f | grep "\./rootfs" | grep -i '\.squashfs$' | while IFS= read LINE ; do
    ISO_ROOTFS="$LINE";
    ISO_ROOTFS_NAME=`echo ${ISO_ROOTFS} | awk -F "/" '{print $NF}' | awk -F'.squashfs' '{print $1}'`;
    CONTAINER_IMAGE_NAME_LOCAL="zasfe/${ISO_FILE_OS_NAME_VERSION}:${ISO_ROOTFS_NAME}";
    CONTAINER_IMAGE_NAME_REMOTE="zasfe/${ISO_FILE_OS_NAME}:${ISO_FILE_VERSION}.${ISO_ROOTFS_NAME}"
    CONTAINER_IMAGE_NAME_REMOTE_SHORT="zasfe/${ISO_FILE_OS_NAME}:${ISO_FILE_VERSION}"
       
        
    # example value
    # ISO_ROOTFS : ./rootfs/casper/ubuntu-server-minimal.squashfs
    # ISO_ROOTFS_NAME : ubuntu-server-minimal
    # CONTAINER_IMAGE_NAME_LOCAL : zasfe/ubuntu-18.04.6:ubuntu-server-minimal
    # CONTAINER_IMAGE_NAME_REMOTE : zasfe/ubuntu:18.04.6-live-server-amd64.iso.ubuntu-server-minimal
    # CONTAINER_IMAGE_NAME_REMOTE_SHORT : zasfe/ubuntu:18.04.6-live-server-amd64.iso
    
    
    echo -e "\033[34m  ## STEP 3-1 ::: unsquash - ${ISO_ROOTFS}  \033[0m";
    test -d unsquashfs && rm -rf unsquashfs
    mkdir -p unsquashfs
    
    unsquashfs -f -d unsquashfs/ ${ISO_ROOTFS};
    
    echo -e "\033[34m  ## STEP 3-2 ::: make container images - ${CONTAINER_IMAGE_NAME_LOCAL} \033[0m";
    tar -C unsquashfs -c . | docker import - ${CONTAINER_IMAGE_NAME_LOCAL}

    echo -e "\033[34m  ## STEP 3-3 ::: test running container - ${CONTAINER_IMAGE_NAME_LOCAL} \033[0m";
    docker run --rm -h myos -t ${CONTAINER_IMAGE_NAME_LOCAL} cat /etc/os-release | grep -i PRETTY_NAME

    if [ $? -eq 0 ]; then
        # OK
        echo -e "\033[34m  ## STEP 3-4 ::: container image push - ${CONTAINER_IMAGE_NAME_REMOTE} \033[0m";
        docker tag ${CONTAINER_IMAGE_NAME_LOCAL} ${CONTAINER_IMAGE_NAME_REMOTE}
        docker tag ${CONTAINER_IMAGE_NAME_LOCAL} ${CONTAINER_IMAGE_NAME_REMOTE_SHORT}
        docker push ${CONTAINER_IMAGE_NAME_REMOTE}
        if [ $? -eq 0 ]; then
            echo -e "\033[34m  ## STEP 3-5 ::: container image push - finish\033[0m";
            docker push ${CONTAINER_IMAGE_NAME_REMOTE_SHORT}
            docker image rm ${CONTAINER_IMAGE_NAME_REMOTE}
            docker image rm ${CONTAINER_IMAGE_NAME_LOCAL}
        else
            echo -e "\033[34m  ## STEP 3-Fail ::: container image push - Fail\033[0m";
            docker push ${CONTAINER_IMAGE_NAME_REMOTE} && docker push ${CONTAINER_IMAGE_NAME_REMOTE_SHORT}
            docker image rm ${CONTAINER_IMAGE_NAME_LOCAL}
        fi
        echo "";
    else
        echo -e "\033[34m  ## STEP 3-Fail ::: container image delete ${CONTAINER_IMAGE_NAME_LOCAL}  \033[0m";
        docker image rm ${CONTAINER_IMAGE_NAME_LOCAL}
        rm -rf ./unsquashfs
        mkdir -p unsquashfs
    fi

done

exit 0;

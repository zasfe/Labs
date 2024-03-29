#!/bin/bash
# Openstack Get images
# https://docs.openstack.org/image-guide/obtain-images.html

source /root/keystonerc_admin
source /root/admin

mkdir -p /home/images/cirros
cd /home/images/cirros
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create "cirros-0.4.0-x86_64" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public


mkdir -p /home/images/centos
cd /home/images/centos

wget http://cloud.centos.org/centos/6/images/CentOS-6-x86_64-GenericCloud.qcow2
openstack image create "CentOS-6-x86_64" --file ./CentOS-6-x86_64-GenericCloud.qcow2 --disk-format qcow2 --container-format bare --public --tag loginaccount:centos

wget https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
openstack image create "CentOS-7-x86_64" --file ./CentOS-7-x86_64-GenericCloud.qcow2 --disk-format qcow2 --container-format bare --public --tag loginaccount:centos

wget https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20220125.1.x86_64.qcow2
openstack image create "CentOS-Stream-8-x86_64-20220125" --file ./CentOS-Stream-GenericCloud-8-20220125.1.x86_64.qcow2 --disk-format qcow2 --container-format bare --public --tag loginaccount:centos

wget https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2
openstack image create "CentOS-8.4-x86_64-20210603" --file ./CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2 --disk-format qcow2 --container-format bare --public --tag loginaccount:centos


mkdir -p /home/images/ubuntu
cd /home/images/ubuntu
wget https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
openstack image create "Ubuntu 14.04.5 LTS (Trusty Tahr)" --file ./trusty-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public

wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
openstack image create "Ubuntu 16.04 LTS (Xenial Xerus)" --file ./xenial-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public

wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
openstack image create "Ubuntu 18.04 LTS (Bionic Beaver)" --file ./bionic-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public

wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
openstack image create "Ubuntu 20.04 LTS (Focal Fossa)" --file ./focal-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public

wget http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
openstack image create "Ubuntu 22.04 LTS (Jammy Jellyfish) built on 20220423" --file ./jammy-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public


# https://rockylinux.org/alternative-images
mkdir -p /home/images/rocky
cd /home/images/rocky

wget https://dl.rockylinux.org/pub/rocky/8.5/images/Rocky-8-GenericCloud-8.5-20211114.2.x86_64.qcow2
openstack image create "Rocky Linux 8.5"  --file ./Rocky-8-GenericCloud-8.5-20211114.2.x86_64.qcow2 --disk-format qcow2 --container-format bare --public






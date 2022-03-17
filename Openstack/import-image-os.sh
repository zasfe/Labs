#!/bin/bash

source /root/keystonerc_admin

mkdir -p /home/images/CentOS
cd /home/images/CentOS
wget http://cloud.centos.org/centos/6/images/CentOS-6-x86_64-GenericCloud.qcow2
openstack image create "CentOS-6-x86_64" --file ./CentOS-6-x86_64-GenericCloud.qcow2 --disk-format qcow2 --container-format bare --public

wget https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
openstack image create "CentOS-7-x86_64" --file ./CentOS-7-x86_64-GenericCloud.qcow2 --disk-format qcow2 --container-format bare --public


mkdir -p /home/images/Ubuntu
cd /home/images/Ubuntu
wget https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
openstack image create "Ubuntu 14.04.5 LTS (Trusty Tahr)" --file ./trusty-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public

wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
openstack image create "Ubuntu 16.04 LTS (Xenial Xerus)" --file ./xenial-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --public

wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
openstack image create "Ubuntu 18.04 LTS (Bionic Beaver)" --file ./bionic-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public

wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
openstack image create "Ubuntu 20.04 LTS (Focal Fossa)" --file ./focal-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public

mkdir -p /home/images/Ubuntu
cd /home/images/Ubuntu
wget http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img
openstack image create "cirros" --file cirros-0.5.2-x86_64-disk.img --disk-format qcow2 --container-format bare --public

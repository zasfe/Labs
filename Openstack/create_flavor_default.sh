#!/bin/bash

. admin

openstack flavor create m1.tiny --ram 512 --disk 0 --vcpus 1
openstack flavor create m1.smaller --ram 1024 --disk 0 --vcpus 1
openstack flavor create m1.small --ram 2048 --disk 10 --vcpus 1
openstack flavor create m1.medium --ram 3072 --disk 10 --vcpus 2
openstack flavor create m1.large --ram 8192 --disk 10 --vcpus 4
openstack flavor create m1.xlarge --ram 8192 --disk 10 --vcpus 8

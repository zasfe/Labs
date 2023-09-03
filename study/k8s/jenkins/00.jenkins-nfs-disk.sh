#!/usr/bin/env bash

./nfs-exporter.sh jenkins

chown 1000:1000 /nfs_shared/jenkins

ls -n /nfs_shared

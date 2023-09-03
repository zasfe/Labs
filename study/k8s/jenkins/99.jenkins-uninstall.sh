#!/usr/bin/env bash

# jenkins uninstall
echo - command: helm uninstall jenkins
helm uninstall jenkins

# jenkins file delete
echo "- command: rm -rf /nfs_shared/jenkins/*"
rm -rf /nfs_shared/jenkins/*
rm -rf /nfs_shared/jenkins/.* 

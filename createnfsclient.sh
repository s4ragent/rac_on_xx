#!/bin/bash
yum -y install nfs-utils
mkdir -p /mnt/config
mkdir -p /mnt/data
mount -t nfs -o vers=4 10.140.0.5:/shared_config /mnt/config
mount -t nfs -o vers=4 10.140.0.5:/shared_data /mnt/data

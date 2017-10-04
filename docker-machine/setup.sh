#!/bin/bash
sudo yum -y install docker-engine parted
sudo rm -f /etc/systemd/system/docker.service.d/docker-sysconfig.conf
sudo parted -s /dev/sda unit Gib mkpart primary 32 100% set 3 lvm on
sudo pvcreate /dev/sda3
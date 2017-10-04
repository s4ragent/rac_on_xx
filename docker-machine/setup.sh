#!/bin/bash
sudo yum -y install parted
sudo parted -s /dev/sda unit Gib mkpart primary 36.5 100% set 3 lvm on
sudo pvcreate /dev/sda3
sudo vgextend vg_main /dev/sda3
sudo lvextend -l +100%FREE /dev/mapper/vg_main-lv_root
sudo xfs_growfs /
#
sudo yum -y install docker-engine
sudo rm -f /etc/systemd/system/docker.service.d/docker-sysconfig.conf
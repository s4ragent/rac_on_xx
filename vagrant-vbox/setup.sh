#!/bin/bash
sudo yum -y install parted
sudo parted -s /dev/sda unit Gib mkpart primary 36.5 100% set 3 lvm on
sudo pvcreate /dev/sda3
sudo vgextend vg_main /dev/sda3
sudo lvextend -l +100%FREE /dev/mapper/vg_main-lv_root
sudo xfs_growfs /
ethtool -K eth0 tso off gro off gso off tx off rx off
ethtool -K eth1 tso off gro off gso off tx off rx off
chmod u+x /etc/rc.d/rc.local
echo "ethtool -K eth0 tso off gro off gso off tx off rx off" >> /etc/rc.d/rc.local
echo "ethtool -K eth1 tso off gro off gso off tx off rx off" >> /etc/rc.d/rc.local
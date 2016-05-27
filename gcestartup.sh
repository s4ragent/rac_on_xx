#!/bin/bash
yum -y install git
git clone https://github.com/s4ragent/rac_on_gce /root/rac_on_gce
cd /root/rac_on_gce
if [ ! -e  /var/tmp/swap.img ]; then
  bash ./createswap.sh
fi
if [ ! -e  /etc/oracle-release ]; then
  bash ./centos72oel7.sh
fi
if [ ! -e  /etc/vxlan/all.ip ]; then
  bash ./install_vxlan.sh
fi




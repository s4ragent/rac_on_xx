#!/bin/bash
yum -y install git
git clone https://github.com/s4ragent/rac_on_gce /root/rac_on_gce
if [ ! -e  /var/tmp/swap.img ]; then
  bash /root/rac_on_gce/createswap.sh
fi
if [ ! -e  /etc/oracle-release ]; then
  bash /root/rac_on_gce/centos72oel7.sh
fi





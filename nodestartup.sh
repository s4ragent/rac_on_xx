#!/bin/bash
if [ ! -e  /root/rac_on_gce ]; then
  yum -y install git
  git clone https://github.com/s4ragent/rac_on_gce /root/rac_on_gce
fi
cd /root/rac_on_gce

bash ./disablesecurity.sh

HasSwap=`free | grep Swap | awk '{print $2}'`
if [ "$HasSwap" = "0" ]; then
  bash ./createswap.sh
fi

if [ ! -e  /etc/oracle-release ]; then
  bash ./centos72oel7.sh
  exit
fi

if [ ! -e  /etc/addn-hosts ]; then
  bash ./dnsmasq_nm.sh
fi

if [ ! -e  /etc/vxlan/all.ip ]; then
  bash -x ./install_vxlan.sh >> /tmp/vxlan.log 2>&1
fi

if [ ! -e  /home/oracle ]; then
  bash -x ./createuser.sh
  bash -x ./createnfsclient.sh
fi




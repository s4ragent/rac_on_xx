#!/bin/bash
if [ ! -e  /root/rac_on_gce ]; then
  yum -y install git
  git clone https://github.com/s4ragent/rac_on_gce /root/rac_on_gce
fi
cd /root/rac_on_gce
source ./common.sh

if [ ! -e  /root/disablesecuritydone ]; then
  bash ./disablesecurity.sh
fi


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

PreRPM=`rpm -qa | grep $PreInstallRPM | wc -l`
if [ $PreRPM -gt 0 ]; then
  yum -y install $PreInstallRPM
fi

Kernel=` grep grid /etc/security/limits.conf | wc -l`
if [ $Kernel -gt 0 ]; then
  bash ./setupkernel.sh
fi

if [ ! -e  /etc/ntp.conf ]; then
  systemctl stop ntpd
  systemctl disable ntpd
  mv /etc/ntp.conf /etc/ntp.conf.original
  rm -f /var/run/ntpd.pid
fi


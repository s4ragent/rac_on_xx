#!/bin/bash
if [ ! -e  /root/rac_on_xx ]; then
  sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
  yum clean all
  yum -y install git
  git clone https://github.com/s4ragent/rac_on_xx /root/rac_on_xx
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
  reboot
  exit
fi

if [ ! -e  /etc/addn-hosts ]; then
  bash ./dnsmasq_nm.sh
fi

if [ ! -e  /etc/vxlan/all.ip ]; then
  bash -x ./install_vxlan.sh >> /tmp/vxlan.log 2>&1
fi

if [ ! -e  /root/hostnamedone ]; then
  bash -x ./sethostname.sh
  reboot
  exit
fi

if [ ! -e  /root/createuser ]; then
  bash -x ./createuser.sh
fi

if [ ! -e  /root/createnfsclient ]; then
  bash -x ./createnfsclient.sh
fi

PreRPM=`rpm -qa | grep $PreInstallRPM | wc -l`
if [ $PreRPM -eq 0 ]; then
  yum -y install $PreInstallRPM
fi

if [ ! -e  /etc/security/limits.d/${LimitsConf}-grid.conf ]; then
  bash ./limits.sh
fi

if [ ! -e  /etc/ntp.conf ]; then
  systemctl stop ntpd
  systemctl disable ntpd
  mv /etc/ntp.conf /etc/ntp.conf.original
  rm -f /var/run/ntpd.pid
fi

MyNumber=`getmynumber`
nodename=`getnodename $MyNumber`
touch $WORK/$nodename

if [ ! -e  /home/grid/.ssh/id_rsa ]; then
  bash ./createsshkey.sh
fi

if [ ! -e  /root/downloaded ]; then
  bash ./download.sh
fi

if [ ! -e  /root/createdb ]; then
  bash ./racutil.sh install_grid_db_dbca
fi

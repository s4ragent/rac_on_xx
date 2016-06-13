#!/bin/bash
cd /root/rac_on_xx
source ./common.sh


#if [ ! -e  /root/xrdpdone ]; then
#  bash ./xrdp.sh
#fi

PreRPM=`rpm -qa | grep $PreInstallRPM | wc -l`
if [ $PreRPM -eq 0 ]; then
  yum -y install $PreInstallRPM
fi

if [ ! -e  /etc/addn-hosts ]; then
  bash ./dnsmasq_systemd.sh
fi

if [ ! -e  /etc/vxlan/all.ip ]; then
  bash -x ./install_vxlan_systemd.sh
fi

if [ ! -e  /root/createuserdone ]; then
  bash -x ./createuser.sh
fi

if [ ! -e  /root/createnfsclientdone ]; then
  bash -x ./createnfsclient.sh
fi

if [ ! -e  /root/disablesecuritydone ]; then
  bash ./disablesecurity.sh
fi

if [ ! -e  /etc/security/limits.d/${LimitsConf}-grid.conf ]; then
  bash ./limits.sh
fi

if [ -e  /etc/ntp.conf ]; then
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

cd /root/rac_on_xx
if [ "$MyNumber" = "1" ] ; then
  if [ ! -e  /root/createdb ]; then
#    bash ./racutil.sh install_grid_db_dbca
  fi
fi

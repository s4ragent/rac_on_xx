#!/bin/bash

if [ ! -e  /root/rac_on_gce ]; then
  sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
  yum clean all
  yum -y install git
  git clone https://github.com/s4ragent/rac_on_gce /root/rac_on_gce
fi
cd /root/rac_on_gce

source ./common.sh
if [ ! -e  /root/disablesecuritydone ]; then
  bash ./disablesecurity.sh
fi

if [ ! -e /nfs ]; then
  bash ./createnfs.sh
fi

#!/bin/bash
if [ ! -e  /root/rac_on_gce ]; then
  yum -y install git
  git clone https://github.com/s4ragent/rac_on_gce /root/rac_on_gce
fi
cd /root/rac_on_gce

if [ ! -e /nfs ]; then
  bash ./createnfs.sh
fi

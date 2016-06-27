#!/bin/bash
if [ ! -e  /root/rac_on_xx ]; then
   if [ -e /etc/debian_version ]; then
　  apt-get update
　  apt-get install -y git
　 elif [ -e /etc/redhat-release ]; then
　  sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
    yum clean all
    yum -y install git
   fi
   git clone https://github.com/s4ragent/rac_on_xx /root/rac_on_xx
fi
cd /root/rac_on_xx
source ./common.sh

HasSwap=`free | grep Swap | awk '{print $2}'`
if [ "$HasSwap" = "0" ]; then
  bash ./createswap.sh
fi

curl -sSL https://get.docker.com/ | sh                                                                                                 
systemctl enable docker                                                                                                                
systemctl start docker                                                                                                                 

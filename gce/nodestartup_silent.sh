#!/bin/bash
if [ ! -e  /root/rac_on_xx ]; then
  sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
  yum clean all
  yum -y install git
  git clone https://github.com/s4ragent/rac_on_xx /root/rac_on_xx
fi
cd /root/rac_on_xx/gce
bash ./nodestartup.sh

cd /root/rac_on_xx/gce
if [ ! -e  /root/downloaded ]; then
  bash ./gcedownload.sh
fi

cd /root/rac_on_xx
if [ ! -e  /root/createdb ]; then
  bash ./racutil.sh install_grid_db_dbca
fi

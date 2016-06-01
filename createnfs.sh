#!/bin/bash
source ./common.sh
yum -y install nfs-utils
#http://masahir0y.blogspot.jp/2012/12/nfs-v3-v4-rhelcentosubuntu.html
#https://oracle-base.com/articles/12c/oracle-db-12cr1-rac-installation-on-oracle-linux-6-using-nfs
mkdir -p /nfs/shared_config
mkdir -p /nfs/shared_grid
mkdir -p /nfs/shared_home
mkdir -p /nfs/shared_data
echo "/nfs *(rw,sync,no_wdelay,insecure_locks,no_root_squash,fsid=0,crossmnt)" >> /etc/exports
chmod -R 775 /nfs

systemctl restart rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap

systemctl enable rpcbind
systemctl enable nfs-server

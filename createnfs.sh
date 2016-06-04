#!/bin/bash
source ./common.sh
yum -y install nfs-utils
#http://masahir0y.blogspot.jp/2012/12/nfs-v3-v4-rhelcentosubuntu.html
#https://oracle-base.com/articles/12c/oracle-db-12cr1-rac-installation-on-oracle-linux-6-using-nfs

mkdir -p $NFS_ROOT
mkdir -p "$NFS_ROOT$GRID_CONFIG"
dd if=/dev/zero of=$CRS_DEV bs=1M count=$CRS_DEV_SIZE
mkdir -p "$NFS_ROOT$ORA_DATA"
mkdir -p "$NFS_ROOT$ORA_ORACLE_HOME"
mkdir -p "$NFS_ROOT$GRID_ORACLE_HOME"
mkdir -p "$NFS_ROOT$WORK"

echo "$NFS_ROOT *(rw,sync,no_wdelay,insecure_locks,no_root_squash,fsid=0,crossmnt)" >> /etc/exports
chmod -R 775 $NFS_ROOT


systemctl restart rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap

systemctl enable rpcbind
systemctl enable nfs-server

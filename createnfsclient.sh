#!/bin/bash
source ./common.sh
yum -y install nfs-utils

mkdir -p ${GRID_ORACLE_BASE}
mkdir -p ${GRID_ORACLE_HOME}
mkdir -p ${GRID_CONFIG}
mkdir -p ${ORA_DATA}
mkdir -p ${WORK}

mkdir -p ${ORA_ORACLE_BASE}
mkdir -p ${ORA_ORACLE_HOME}



echo "$NFS_SERVER:${GRID_CONFIG} ${GRID_CONFIG} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab
echo "$NFS_SERVER:${GRID_ORACLE_HOME} ${GRID_ORACLE_HOME} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab
echo "$NFS_SERVER:${ORA_ORACLE_HOME} ${ORA_ORACLE_HOME} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab
echo "$NFS_SERVER:${ORA_DATA} ${ORA_DATA} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab
echo "$NFS_SERVER:${WORK} ${WORK} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab
mount -a

chown -R grid:oinstall ${MOUNT_PATH}
chown -R oracle:oinstall ${ORA_ORACLE_BASE}
chown -R oracle:oinstall ${ORA_ORACLE_HOME}
chmod -R 775 ${MOUNT_PATH}

touch /root/createnfsclientdone

#!/bin/bash
mkdir -p ${GRID_ORACLE_BASE}
mkdir -p ${GRID_ORACLE_HOME}
mkdir -p ${GRID_CONFIG}
mkdir -p ${ORA_DATA}
mkdir -p ${WORK}
chown -R grid:oinstall ${MOUNT_PATH}
mkdir -p ${ORA_ORACLE_BASE}
mkdir -p ${ORA_ORACLE_HOME}
chown oracle:oinstall ${ORA_ORACLE_BASE}
chmod -R 775 ${MOUNT_PATH}



yum -y install nfs-utils
echo "$NFS_SERVER:${GRID_CONFIG} ${GRID_CONFIG} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab
echo "$NFS_SERVER:${GRID_ORACLE_HOME} ${GRID_ORACLE_HOME} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab
echo "$NFS_SERVER:${ORA_ORACLE_HOME} ${ORA_ORACLE_HOME} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab
echo "$NFS_SERVER:${ORA_DATA} ${ORA_DATA} nfs rw,bg,hard,nointr,tcp,vers=4,timeo=600,actimeo=0 0 0" >> /etc/fstab


nas1:/shared_data   /u01/oradata  nfs  rw,bg,hard,nointr,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0  0 0

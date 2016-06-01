#!/bin/bash
mkdir -p ${GRID_ORACLE_BASE}
mkdir -p ${GRID_ORACLE_HOME}
mkdir -p ${SHARED_CONFIG}
mkdir -p ${SHARED_DATA}
chown -R grid:oinstall ${MOUNT_PATH}
mkdir -p ${ORA_ORACLE_BASE}
chown oracle:oinstall ${ORA_ORACLE_BASE}
chmod -R 775 ${MOUNT_PATH}



yum -y install nfs-utils
mkdir -p /mnt/config
mkdir -p /mnt/data
mount -t nfs -o vers=4 10.140.0.5:/shared_config /mnt/config
mount -t nfs -o vers=4 10.140.0.5:/shared_data /mnt/data

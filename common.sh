#!/bin/bash
NFS_SERVER="10.140.0.3"
NODE_LIST="10.140.0.5 10.140.0.6 10.140.0.7"
ISCSI_DISKSIZE=0
NETWORK="192.168.0.0 192.168.100.0"
NETWORKS=($NETWORK)
INSTALL_LANG="ja"
BASE_IP=50
NODEPREFIX="node"
DOMAIN_NAME="public"
SCAN_NAME="scan"
GRID_PASSWORD="grid123"
ORACLE_PASSWORD="oracle123"
NFS_ROOT="/nfs"
GRID_CONFIG="/u01/config"
ORA_DATA="/u01/data"
MOUNT_PATH="/u01"
WORK="/u01/work"
ORA_ORACLE_BASE="/u01/app/oracle"
GRID_ORACLE_BASE="/u01/app/grid"
#####
CRS_PATH=${GRID_CONFIG}
CRS_DEV=${GRID_CONFIG}/crs.img
CRS_DEV_SIZE=30720
CRS_DEV_STRING=${GRID_CONFIG}/*
INSTALL_LANG=ja
CLUSTER_NAME=node-cluster
DBNAME=ORCL
SIDNAME=ORCL
SYSPASSWORD=oracle123
SYSTEMPASSWORD=oracle123
REDOFILESIZE=10
DISKGROUPNAME=CRS
FRA=CRS
ASMPASSWORD=oracle123
CHARSET=AL32UTF8
NCHAR=AL16UTF16
MEMORYTARGET=3200
TEMPLATENAME=General_Purpose.dbc
DATABASETYPE=MULTIPURPOSE
###version specific
ORA_ORACLE_HOME="/u01/app/oracle/product/12.1.0/dbhome_1"
GRID_ORACLE_HOME="/u01/app/12.1.0/grid"
ORAINVENTORY="/u01/app/oraInventory"
PreInstallRPM="oracle-rdbms-server-12cR1-preinstall"
LimitsConf="oracle-rdbms-server-12cR1-preinstall"
DB_MEDIA1="linuxamd64_12102_database_1of2.zip"
DB_MEDIA2="linuxamd64_12102_database_2of2.zip"
GRID_MEDIA1="linuxamd64_12102_grid_1of2.zip"
GRID_MEDIA2="linuxamd64_12102_grid_2of2.zip"
######
GOOGLESTORAGE="gs://s4ragent2848/"


NODELISTS=($NODE_LIST)
NODELISTCOUNT=${#NODELISTS[@]}


getmynumber()
{
	MyIp=`ip a show eth0 | grep "inet " | awk -F '[/ ]' '{print $6}'`
	LIST=`cat /etc/vxlan/all.ip`
	CNT=1
	for i in $LIST ;
	do
	      	if [ $i == $MyIp ]; then
	      		echo $CNT
	      		break
	      	fi
	      	CNT=`expr $CNT + 1`
	done
}

getnodename ()
{
  echo "$NODEPREFIX"`printf "%.3d" $1`
}

## $1 network number, $2 real/vip/priv $3 nodenumber           ### 
## Ex.   network 192.168.0.0 , 192.168.100.0  and BASE_IP=50 >>>##
## getip 0 vip 2 >>> 192.168.0.52 ###
getip ()
{
	SEGMENT=`echo ${NETWORKS[$1]} | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	if [ $2 == "real" ] ; then
  		IP=`expr $BASE_IP + $3`
		echo "${SEGMENT}${IP}"
	elif [ $2 == "vip" ] ; then
		IP=`expr $BASE_IP + 100 + $3`
		echo "${SEGMENT}${IP}"
	elif [ $2 == "host" ] ; then
		IP=`expr $BASE_IP - 10 + $3`
		echo "${SEGMENT}${IP}"
	elif [ $2 == "scan" ] ; then
    		echo "${SEGMENT}`expr $BASE_IP - 20 ` ${SCAN_NAME}.${DOMAIN_NAME} ${SCAN_NAME}"
    		echo "${SEGMENT}`expr $BASE_IP - 20 + 1` ${SCAN_NAME}.${DOMAIN_NAME} ${SCAN_NAME}"
    		echo "${SEGMENT}`expr $BASE_IP - 20 + 2` ${SCAN_NAME}.${DOMAIN_NAME} ${SCAN_NAME}"
	fi
}


case "$1" in
  "getnodename" ) shift;getnodename $*;;
  "getip" ) shift;getip $*;;
  "getmynumber" ) shift;getmynumber $*;;
  * ) echo "Ex " ;;
esac

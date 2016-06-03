#!/bin/bash
source ./common.sh

gridstatus(){
	ssh -i id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null grid@`getip 0 real $1` $GRID_ORACLE_HOME/bin/crsctl status resource -t
}

creatersp()
{
    NODECOUNT=1
    for i in `seq 1 $NODELISTCOUNT`;
    do
      NODENAME=`getnodename $i`
      if [ $NODECOUNT = 1 ] ; then
        CLUSTERNODES="${NODENAME}:${NODENAME}-vip"
      else
        CLUSTERNODES="$CLUSTERNODES,${NODENAME}:${NODENAME}-vip"
      fi
      NODECOUNT=`expr $NODECOUNT + 1`
    done
    
    NODECOUNT=1
    for i in `seq 1 $NODELISTCOUNT`;
	do
		if [ $NODECOUNT = 1 ] ; then
			DB_CLUSTER_NODES=`getnodename $NODECOUNT`
		else
			DB_CLUSTER_NODES="$DB_CLUSTER_NODES,`getnodename $NODECOUNT`"
		fi
			NODECOUNT=`expr $NODECOUNT + 1`
	done
	MyIp=`ip a show eth0 | grep "inet " | awk -F '[/ ]' '{print $6}'`
	#MyNetwork=`echo $MyIp | grep -Po '\d{1,3}\.\d{1,3}\.'`
	#MyNetwork="${MyNetwork}0.0"
        MyNetwork=$(ipcalc -n `ip addr show eth0 | grep 'inet ' | awk '{print $2}'` | awk -F '=' '{print $2}')
    
    cat > /home/grid/asm.rsp <<EOF
oracle.assistants.asm|S_ASMPASSWORD=$ASMPASSWORD
oracle.assistants.asm|S_ASMMONITORPASSWORD=$ASMPASSWORD
EOF

    cat > /home/grid/grid.rsp  <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v12.1.0
ORACLE_HOSTNAME=
INVENTORY_LOCATION=$ORAINVENTORY
SELECTED_LANGUAGES=en,ja
oracle.install.option=CRS_CONFIG
ORACLE_BASE=$GRID_ORACLE_BASE
ORACLE_HOME=$GRID_ORACLE_HOME
oracle.install.asm.OSDBA=asmdba
oracle.install.asm.OSOPER=asmoper
oracle.install.asm.OSASM=asmadmin
oracle.install.crs.config.gpnp.scanName=${SCAN_NAME}.${DOMAIN_NAME}
oracle.install.crs.config.gpnp.scanPort=1521
oracle.install.crs.config.ClusterType=STANDARD
oracle.install.crs.config.clusterName=${CLUSTER_NAME}
oracle.install.crs.config.gpnp.configureGNS=false
oracle.install.crs.config.autoConfigureClusterNodeVIP=
oracle.install.crs.config.gpnp.gnsOption=
oracle.install.crs.config.gpnp.gnsClientDataFile=
oracle.install.crs.config.gpnp.gnsSubDomain=
oracle.install.crs.config.gpnp.gnsVIPAddress=
oracle.install.crs.config.clusterNodes=$CLUSTERNODES
oracle.install.crs.config.networkInterfaceList=eth0:$MyNetwork:3,vxlan0:${NETWORKS[0]}:1,vxlan1:${NETWORKS[1]}:2
oracle.install.crs.config.storageOption=LOCAL_ASM_STORAGE
oracle.install.crs.config.sharedFileSystemStorage.votingDiskLocations=
oracle.install.crs.config.sharedFileSystemStorage.votingDiskRedundancy=
oracle.install.crs.config.sharedFileSystemStorage.ocrLocations=
oracle.install.crs.config.sharedFileSystemStorage.ocrRedundancy=
oracle.install.crs.config.useIPMI=false
oracle.install.crs.config.ipmi.bmcUsername=
oracle.install.crs.config.ipmi.bmcPassword=
oracle.install.asm.SYSASMPassword=$ASMPASSWORD
oracle.install.asm.diskGroup.name=$DISKGROUPNAME
oracle.install.asm.diskGroup.redundancy=EXTERNAL
oracle.install.asm.diskGroup.AUSize=1
oracle.install.asm.diskGroup.disks=$CRS_DEV
oracle.install.asm.diskGroup.diskDiscoveryString=$CRS_DEV_STRING
oracle.install.asm.monitorPassword=$ASMPASSWORD
oracle.install.asm.ClientDataFile=
oracle.install.crs.config.ignoreDownNodes=false
oracle.install.config.managementOption=NONE
oracle.install.config.omsHost=
oracle.install.config.omsPort=
oracle.install.config.emAdminUser=
EOF

cat >/home/oracle/db.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12.1.0
oracle.install.option=INSTALL_DB_SWONLY
ORACLE_HOSTNAME=
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=
SELECTED_LANGUAGES=en,ja
ORACLE_HOME=$ORA_ORACLE_HOME
ORACLE_BASE=$ORA_ORACLE_BASE
oracle.install.db.InstallEdition=EE
oracle.install.db.DBA_GROUP=dba
oracle.install.db.OPER_GROUP=oper
oracle.install.db.BACKUPDBA_GROUP=dba
oracle.install.db.DGDBA_GROUP=dba
oracle.install.db.KMDBA_GROUP=dba
oracle.install.db.rac.configurationType=
oracle.install.db.CLUSTER_NODES=$DB_CLUSTER_NODES
oracle.install.db.isRACOneInstall=
oracle.install.db.racOneServiceName=
oracle.install.db.rac.serverpoolName=
oracle.install.db.rac.serverpoolCardinality=
oracle.install.db.config.starterdb.type=
oracle.install.db.config.starterdb.globalDBName=
oracle.install.db.config.starterdb.SID=
oracle.install.db.ConfigureAsContainerDB=
oracle.install.db.config.PDBName=
oracle.install.db.config.starterdb.characterSet=
oracle.install.db.config.starterdb.memoryOption=
oracle.install.db.config.starterdb.memoryLimit=
oracle.install.db.config.starterdb.installExampleSchemas=
oracle.install.db.config.starterdb.password.ALL=
oracle.install.db.config.starterdb.password.SYS=
oracle.install.db.config.starterdb.password.SYSTEM=
oracle.install.db.config.starterdb.password.DBSNMP=
oracle.install.db.config.starterdb.password.PDBADMIN=
oracle.install.db.config.starterdb.managementOption=
oracle.install.db.config.starterdb.omsHost=
oracle.install.db.config.starterdb.omsPort=
oracle.install.db.config.starterdb.emAdminUser=
oracle.install.db.config.starterdb.emAdminPassword=
oracle.install.db.config.starterdb.enableRecovery=
oracle.install.db.config.starterdb.storageType=
oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=
oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=
oracle.install.db.config.asm.diskGroup=
oracle.install.db.config.asm.ASMSNMPPassword=
MYORACLESUPPORT_USERNAME=
MYORACLESUPPORT_PASSWORD=
SECURITY_UPDATES_VIA_MYORACLESUPPORT=
DECLINE_SECURITY_UPDATES=
PROXY_HOST=
PROXY_PORT=
PROXY_USER=
PROXY_PWD=
EOF

    for i in `seq 1 $NODELISTCOUNT`;
    do
      NODENAME=`getnodename $i`
      echo "$NODENAME ${NODENAME}-vip">> /home/grid/clusterlist.ccf
    done

    chmod 755 /home/grid/grid.rsp
    chmod 755 /home/grid/asm.rsp
    chmod 755 /home/grid/clusterlist.ccf
    chown grid.oinstall /home/grid/grid.rsp
    chown grid.oinstall /home/grid/asm.rsp
    chown grid.oinstall /home/grid/clusterlist.ccf
    
    chmod 755 /home/oracle/db.rsp
    chown oracle.oinstall /home/oracle/db.rsp
}


exedbca(){
	dbcaoption="-silent -createDatabase -templateName $TEMPLATENAME -gdbName $DBNAME -sid $SIDNAME" 
	dbcaoption="$dbcaoption -SysPassword $SYSPASSWORD -SystemPassword $SYSTEMPASSWORD -emConfiguration NONE -redoLogFileSize $REDOFILESIZE"
	dbcaoption="$dbcaoption -recoveryAreaDestination $FRA -storageType ASM -asmSysPassword $ASMPASSWORD -diskGroupName $DISKGROUPNAME"
	dbcaoption="$dbcaoption -characterSet $CHARSET -nationalCharacterSet $NCHAR -totalMemory $MEMORYTARGET -databaseType $DATABASETYPE"

	NODECOUNT=1
	for i in `seq 1 $NODELISTCOUNT`;
	do
		if [ $NODECOUNT = 1 ] ; then
			dbcaoption="$dbcaoption -nodelist `getnodename $NODECOUNT`"
		else
			dbcaoption="$dbcaoption,`getnodename $NODECOUNT`"
		fi
			NODECOUNT=`expr $NODECOUNT + 1`
	done
	$ORA_ORACLE_HOME/bin/dbca $dbcaoption
}

deletedb(){
	dbcaoption="-silent -deleteDatabase -sourceDB $DBNAME" 
	$ORA_ORACLE_HOME/bin/dbca $dbcaoption
}

exedbca2(){
	dbcaoption="-silent -createDatabase -templateName $TEMPLATENAME -gdbName $DBNAME -sid $SIDNAME" 
	dbcaoption="$dbcaoption -SysPassword $SYSPASSWORD -SystemPassword $SYSTEMPASSWORD -emConfiguration NONE -redoLogFileSize $REDOFILESIZE"
	dbcaoption="$dbcaoption -recoveryAreaDestination $FRA -storageType ASM -asmSysPassword $ASMPASSWORD -diskGroupName $DISKGROUPNAME"
	dbcaoption="$dbcaoption -characterSet $CHARSET -nationalCharacterSet $NCHAR -totalMemory $MEMORYTARGET -databaseType $DATABASETYPE"
       
        dbcaoption="$dbcaoption -nodelist `getnodename 1`"
	$ORA_ORACLE_HOME/bin/dbca $dbcaoption

	for i in `seq 2 $NODELISTCOUNT`;
	do
        	dbcaoption="-silent -addInstance -gdbName $DBNAME"
		dbcaoption="$dbcaoption -nodelist `getnodename $i`"
		$ORA_ORACLE_HOME/bin/dbca $dbcaoption
	done
}

case "$1" in
  "gridstatus" ) shift;gridstatus $*;;
  "creatersp" ) shift;creatersp $*;;
  "exedbca" ) shift;exedbca $*;;
  "exedbca2") shift;exedbca2 $*;;
  "exessh" ) shift;exessh $*;;
  "exerootssh" ) shift;exerootssh $*;;
  * ) echo "Ex " ;;
esac

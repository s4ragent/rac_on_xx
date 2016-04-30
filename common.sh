parse_yaml(){
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

#get variables from vars.yml
eval $(parse_yaml vars.yml)

NETWORKS=($NETWORK)

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

createvxlanconf()
{
        local vxlanip=`getip $1 $2 $3`
        #get network prefix     
        eval `ipcalc -s -p ${NETWORKS[$1]}/24`
        cat >/etc/vxlan/vxlan${1}.conf <<EOF
vInterface = vxlan${1}
Id = 1${1}
Ether = eth0
List = /etc/vxlan/all.ip
Address = ${vxlanip}/${PREFIX}
EOF
        chkconfig vxlan on
        service vxlan restart
}

createansiblehost(){
	cat > hosts/localhost <<EOF
[localhost]
127.0.0.1

EOF
	nodename=`getnodename 1`
	nodeip=`getip 0 real 1`

	cat >> hosts/localhost <<EOF
[node1]
$nodeip fqdn=${nodename}.${DOMAIN_NAME} hostname=${nodename} 

EOF
	cat >> hosts/localhost <<EOF
[node_other]
EOF
	for i in `seq 2 $1`; do
		nodename=`getnodename $i`
		nodeip=`getip 0 real $i`
		echo "$nodeip fqdn=${nodename}.${DOMAIN_NAME} hostname=${nodename}" >> hosts/localhost
	done

}

createuser(){
  ###delete user ###
  userdel -r oracle
  userdel -r grid
  groupdel dba
  groupdel oinstall
  groupdel oper
  groupdel asmadmin
  groupdel asmdba
  groupdel asmoper

##create user/group####
  groupadd -g 601 oinstall
  groupadd -g 602 dba
  groupadd -g 603 oper
  groupadd -g 2001 asmadmin
  groupadd -g 2002 asmdba
  groupadd -g 2003 asmoper
  useradd -u 501 -m -g oinstall -G dba,oper,asmdba -d /home/oracle -s /bin/bash -c"Oracle Software Owner" oracle
  useradd -u 2001 -m -g oinstall -G asmadmin,asmdba,asmoper -d /home/grid -s /bin/bash -c "Grid Infrastructure Owner" grid

### edit bash &bashrc ###
   cat >> /home/oracle/.bashrc <<'EOF'
#this is for oracle install#
if [ -t 0 ]; then
   stty intr ^C
fi
EOF

  cat >> /home/grid/.bashrc <<'EOF'
#this is for oracle install#
if [ -t 0 ]; then
   stty intr ^C
fi
EOF

  cat >> /home/oracle/.bash_profile <<EOF
### for oracle install ####
export ORACLE_BASE=${ORA_ORACLE_BASE}
export ORACLE_HOME=${ORA_ORACLE_HOME}
EOF

  cat >> /home/oracle/.bash_profile <<'EOF'
export TMPDIR=/tmp
export TEMP=/tmp
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/jdk/bin:${PATH}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
EOF

  cat >> /home/grid/.bash_profile <<EOF
### for grid install####
export ORACLE_BASE=${GRID_ORACLE_BASE}
export ORACLE_HOME=${GRID_ORACLE_HOME}
EOF

  cat >> /home/grid/.bash_profile <<'EOF'
export TMPDIR=/tmp
export TEMP=/tmp
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/jdk/bin:${PATH}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
EOF
}

createsshkey(){
	rm -rf ./id_rsa*
	rm -rf ./known_hosts
	ssh-keygen -t rsa -P "" -f ./id_rsa
    
	for i in `seq 1 $1`; do
      		nodename=`getnodename $i`
      		nodeip=`getip 0 real $i`
      		ssh-keyscan -T 180 -t rsa $nodename >> ./known_hosts
      		ssh-keyscan -T 180 -t rsa $nodeip >> ./known_hosts
    	done
}

createdns(){

cat << EOF >/etc/hosts
127.0.0.1       localhost
EOF

getip 0 scan >> /etc/hosts
for i in `seq 1 64`; do
  nodename=`getnodename $i`
  echo "`getip 0 real $i` $nodename".${DOMAIN_NAME}" $nodename" >> /etc/hosts
  vipnodename=$nodename"-vip"
  vipi=`expr $i + 100`
  echo "`getip 0 real $vipi` $vipnodename".${DOMAIN_NAME}" $vipnodename" >> /etc/hosts
done


cat << EOT >> /etc/dnsmasq.conf
listen-address=127.0.0.1
resolv-file=/etc/resolv.dnsmasq.conf
conf-dir=/etc/dnsmasq.d
user=root
EOT

cat << EOT >> /etc/resolv.dnsmasq.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOT
chkconfig dnsmasq on
service dnsmasq start
}

createrules()
{
  cat >/etc/udev/rules.d/90-oracle.rules <<'EOF'
KERNEL=="loop3[0-9]", OWNER:="grid", GROUP:="asmadmin", MODE:="666"
EOF
}
setupkernel(){
sed -i 's/oracle/#oracle/' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
#this is for oracle install#
oracle - nproc 16384
oracle - nofile 65536
oracle soft stack 10240
oracle hard  memlock  3145728
grid - nproc 16384
grid - nofile 65536
grid soft stack 10240
EOF
echo "net.ipv4.ip_local_reserved_ports=42424" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts=0" >> /etc/sysctl.conf

##disable ntp####
chkconfig ntpd off
mv /etc/ntp.conf /etc/ntp.conf.original
rm /var/run/ntpd.pid

##disable NetworkManager
chkconfig NetworkManager off
}

exessh(){
	ssh -i id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $1@`getnodename $2`
}

exerootssh(){
	ssh -i $1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@`getnodename $2`
}

createoraclehome(){
        isFdisk=`fdisk -l | grep ${ORACLE_HOME_DEVICE}1 | wc -l`

        sfdisk -uM ${ORACLE_HOME_DEVICE} <<EOF
,,83
EOF
        sleep 15

        if [ "$isFdisk" = "0" ] ; then
                mkfs.xfs -f ${ORACLE_HOME_DEVICE}1
        fi

        echo "${ORACLE_HOME_DEVICE}1    ${MOUNT_PATH}   xfs    defaults        0 0" >> /etc/fstab
        mkdir ${MOUNT_PATH}
	chown grid:oinstall ${MOUNT_PATH}
        mount ${MOUNT_PATH}
	xfs_growfs -d ${MOUNT_PATH}

        if [ ! -d ${GRID_ORACLE_BASE} ] ; then
                mkdir -p ${GRID_ORACLE_BASE}
                mkdir -p ${GRID_ORACLE_HOME}
                chown -R grid:oinstall ${MOUNT_PATH}
                mkdir -p ${ORA_ORACLE_BASE}
                chown oracle:oinstall ${ORA_ORACLE_BASE}
                chmod -R 775 ${MOUNT_PATH}
        fi
}

createnfsclient(){
echo "$1:/ $NFS_PATH nfs rw,bg,hard,nointr,tcp,noac,vers=4,timeo=600,actimeo=0,rsize=$RSIZE,wsize=$WSIZE 0 0" >> /etc/fstab
mkdir $NFS_PATH
mount $NFS_PATH
chown -R grid:oinstall $NFS_PATH
chmod -R 775 $NFS_PATH
chkconfig netfs on
}

cleanGIDB(){
	mv $ORA_ORACLE_HOME $MOUNT_PATH/tmp
        rm -rf $ORA_ORACLE_BASE
        rm -rf $ORAINVENTORY
	rm -rf $GRID_ORACLE_BASE
        mkdir -p $ORA_ORACLE_BASE
	mkdir -p $GRID_ORACLE_BASE
	mkdir -p $ORA_ORACLE_HOME
	mv $MOUNT_PATH/tmp/* $ORA_ORACLE_HOME
	rm -rf $MOUNT_PATH/tmp
	chown -R grid:oinstall ${MOUNT_PATH}
        chown -R oracle:oinstall ${ORA_ORACLE_BASE}
        chown -R oracle:oinstall ${ORA_ORACLE_HOME}
	chown -R grid:oinstall $GRID_ORACLE_BASE

#        $GRID_ORACLE_HOME/crs/install/rootcrs.pl -deconfig -force -verbose
#        OLD_IFS=$IFS
#        local IFS='/'
#        set -- $GRID_ORACLE_HOME
#        local IFS=$OLD_IFS
#        for i in "$@"
#        do
#                if [ "$i" != "" ] ; then
#                        CHMODPATH=${CHMODPATH}"/"${i}
#                        chown grid:oinstall $CHMODPATH
#                fi
#        done
#        rm -rf $ORAINVENTORY
#        mkdir -p $ORAINVENTORY
#        chown grid:oinstall $ORAINVENTORY
#        chown grid:oinstall $GRID_ORACLE_BASE
#        chown -R grid:oinstall $GRID_ORACLE_HOME

	cd $GRID_ORACLE_HOME
	HOSTNAME=`hostname -s`
        rm -rf log/$HOSTNAME
        rm -rf gpnp/$HOSTNAME
        find gpnp -type f -exec rm -f {} \;
        rm -rf cfgtoollogs/*
        rm -rf crs/init/*
        rm -rf cdata/*
        rm -rf crf/*
        rm -rf network/admin/*.ora
        rm -rf crs/install/crsconfig_params
        find . -name '*.ouibak' -exec rm {} \;
        find . -name '*.ouibak.1' -exec rm {} \;
        rm -rf root.sh*
        rm -rf rdbms/audit/*
        rm -rf rdbms/log/*
        rm -rf inventory/backup/*
	rm -rf $ORA_ORACLE_HOME/network/admin/*.ora
	rm -rf $GRID_ORACLE_HOME/install/*.log
}

creatersp()
{
    NODECOUNT=1
    for i in `seq 1 $1`;
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
    for i in `seq 1 $1`;
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

    for i in `seq 1 $1`;
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
	for i in `seq 1 $1`;
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

	for i in `seq 2 $1`;
	do
        	dbcaoption="-silent -addInstance -gdbName $DBNAME"
		dbcaoption="$dbcaoption -nodelist `getnodename $i`"
		$ORA_ORACLE_HOME/bin/dbca $dbcaoption
	done
}

createimg(){
	rm -rf $CRS_PATH	
	mkdir -p $CRS_PATH
	#dd if=/dev/zero of=$CRS_DEV bs=1M count=`expr $1 \* 1024`
	qemu-img create $CRS_DEV ${1}G
        chown -R grid:asmadmin $CRS_PATH
        chmod 0660 $CRS_DEV
}

gridstatus(){
	ssh -i id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null grid@`getip 0 real $1` $GRID_ORACLE_HOME/bin/crsctl status resource -t
}

create_clonepl_startsh()
{
CLUSTER_NODES="{"
for i in `seq 1 $1`; do
	HOSTNAME=`getnodename $i`
        if [ $i != 1 ] ; then
                CLUSTER_NODES=${CLUSTER_NODES},
        fi
        CLUSTER_NODES=${CLUSTER_NODES}${HOSTNAME}
done
CLUSTER_NODES=${CLUSTER_NODES}\}
cat >/home/grid/start.sh <<EOF
#!/bin/bash
ORACLE_BASE=$GRID_ORACLE_BASE
GRID_HOME=$GRID_ORACLE_HOME
THIS_NODE=\`hostname -s\`
E01=ORACLE_BASE=\${ORACLE_BASE}
E02=ORACLE_HOME=\${GRID_HOME}
E03=ORACLE_HOME_NAME=OraGridHome1
E04=INVENTORY_LOCATION=$ORAINVENTORY
C01="CLUSTER_NODES=$CLUSTER_NODES"
C02="LOCAL_NODE=\$THIS_NODE"
perl \${GRID_HOME}/clone/bin/clone.pl -silent \$E01 \$E02 \$E03 \$E04 \$C01 \$C02
EOF

chmod 755 /home/grid/start.sh
chown grid.oinstall /home/grid/start.sh

cat >/home/oracle/start.sh <<EOF
#!/bin/bash
ORACLE_BASE=$ORA_ORACLE_BASE
ORACLE_HOME=$ORA_ORACLE_HOME
cd \$ORACLE_HOME/clone
THIS_NODE=\`hostname -s\`

E01=ORACLE_HOME=$ORA_ORACLE_HOME
E02=ORACLE_HOME_NAME=OraDBRAC
E03=ORACLE_BASE=$ORA_ORACLE_BASE
C01="-O CLUSTER_NODES=$CLUSTER_NODES"
C02="-O LOCAL_NODE=\$THIS_NODE"
perl \$ORACLE_HOME/clone/bin/clone.pl \$E01 \$E02 \$E03 \$C01 \$C02
EOF

chmod 755 /home/oracle/start.sh
chown oracle.oinstall /home/oracle/start.sh
}
case "$1" in
  "gridstatus" ) shift;gridstatus $*;;
  "createoraclehome" ) shift;createoraclehome $*;;
  "createimg" ) shift;createimg $*;;
  "creatersp" ) shift;creatersp $*;;
  "createsshkey" ) shift;createsshkey $*;;
  "exedbca" ) shift;exedbca $*;;
  "exedbca2") shift;exedbca2 $*;;
  "deletedb") shift;deletedb $*;;
  "getip" ) shift;getip $*;;
  "createdns" ) shift;createdns $*;;
  "createuser" ) shift;createuser $*;;
  "createvxlanconf" ) shift;createvxlanconf $*;;
  "createnfsclient" ) shift;createnfsclient $*;;
  "createansiblehost" ) shift;createansiblehost $*;;
  "setupkernel" ) shift;setupkernel $*;;
  "cleanGIDB" ) shift;cleanGIDB $*;;
  "create_clonepl_startsh" ) shift;create_clonepl_startsh $*;;
  "exessh" ) shift;exessh $*;;
  "exerootssh" ) shift;exerootssh $*;;
  * ) echo "Ex " ;;
esac

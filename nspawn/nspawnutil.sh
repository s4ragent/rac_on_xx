#!/bin/bash

VIRT_TYPE="nspawn"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){

	NODENAME=$1
	IP=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID=${NODENAME}
	
	cp -R /var/lib/machines/rac_template /var/lib/machines/$INSTANCE_ID
	
	SEGMENT=`echo $NSPAWNSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	
	cat << EOF > /var/lib/machines/$INSTANCE_ID/etc/sysconfig/network-scripts/ifcfg-host0
DEVICE=host0
TYPE=Ethernet
IPADDR=$IP
GATEWAY=${SEGMENT}1
NETMASK=255.255.255.0
ONBOOT=yes
BOOTPROTO=static
NM_CONTROLLED=no
DELAY=0
EOF

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
                                                  
	systemd-machine-id-setup --root=/var/lib/machines/$INSTANCE_ID
	machinectl start $INSTANCE_ID
	sleep 20s

}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	
	if [  ! -e /etc/systemd/system/multi-user.target.wants/createbr.service ] ; then
		SEGMENT=`echo $NSPAWNSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
		ipcmd=`which ip`
		brctlcmd=`which brctl`
		iptablescmd=`which iptables`
		cat << EOF > /etc/systemd/system/multi-user.target.wants/createbr.service
[Unit]
Description=createbr
Requires=network.target
Before=network.target remote-fs.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=-$brctlcmd addbr $BRNAME ; $ipcmd addr add dev $BRNAME ${SEGMENT}1/24 ; $ipcmd link set up dev $BRNAME
ExecStartPost=-$iptablescmd -t nat -N $BRNAME ; $iptablescmd -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j $BRNAME ; $iptablescmd -t nat -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j $BRNAME ; $iptablescmd -t nat -A POSTROUTING -s ${SEGMENT}0/24 ! -o $BRNAME -j MASQUERADE ;	$iptablescmd -t nat -A $BRNAME -i $BRNAME -j RETURN ; $iptablescmd -I FORWARD -i $BRNAME -o $BRNAME -j ACCEPT ; $iptablescmd -I FORWARD -i $BRNAME ! -o $BRNAME -j ACCEPT ; $iptablescmd -I FORWARD -o $BRNAME -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT ; /sbin/sysctl -w net.ipv4.ip_forward=1
User=root
Group=root
[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
	systemctl start createbr.service
	fi
	
#	sysctl -w net.core.rmem_default = 2621440
#	sysctl -w net.core.rmem_max = 41943040
#	sysctl -w net.core.wmem_default = 2621440
#	sysctl -w net.core.wmem_max = 10485760
#	sysctl -w fs.aio-max-nr = 10485760
#	sysctl -w fs.file-max = 68157440
#	sysctl -w net.ipv4.ip_local_port_range = 9000 65500
	
	if [  ! -e $ansible_ssh_private_key_file ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi

	nspawncmd=`which systemd-nspawn`
	ipcmd=`which ip`
	mkdir -p /etc/systemd/system/systemd-nspawn@.service.d
	if [  ! -e /etc/systemd/system/systemd-nspawn@.service.d/override.conf ] ; then
			cat << EOF  > /etc/systemd/system/systemd-nspawn@.service.d/override.conf
[Service]
ExecStart=
ExecStart=$nspawncmd --quiet --keep-unit --boot --link-journal=try-guest --machine=%I --network-bridge=$BRNAME --bind-ro=/boot --capability=all
ExecStopPost=-${ipcmd} link del vb-%I
KillMode=
KillMode=mixed                                                                    
Type=
Type=notify 
RestartForceExitStatus=
RestartForceExitStatus=133
SuccessExitStatus=
SuccessExitStatus=133  
Slice=
Slice=machine.slice
Delegate=
Delegate=yes
EOF

	systemctl daemon-reload
	fi

	if [  ! -e /var/lib/machines/rac_template ] ; then
		buildimage
	fi

	STORAGEIP=`get_Internal_IP storage`
	run "storage" $STORAGEIP 0 "storage"
	
	common_update_all_yml "STORAGE_SERVER: $STORAGEIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_Internal_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODEIP $i "dbserver"
	done
	
	sleep 30s
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
   	common_deleteall $*
	#### VIRT_TYPE specific processing ###
	if [ -e "$ansible_ssh_private_key_file" ]; then
   		rm -rf ${ansible_ssh_private_key_file}*
	fi

	systemctl stop 'systemd-nspawn@rac_template.service'
	ip link del vb-rac_template
		
	systemctl stop 'systemd-nspawn@storage.service'
	ip link del vb-storage
	
	
	for i in `seq 1 100`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		systemctl stop 'systemd-nspawn@'${NODENAME}.service
		ip link del vb-${NODENAME}
	done
	
	rm -rf /var/lib/machines/*
	ip link set $BRNAME down
	brctl delbr $BRNAME
	systemctl stop createbr.service
  	
	rm -rf /tmp/$CVUQDISK
	rm -rf /etc/systemd/system/systemd-nspawn@.service.d/override.conf
	rm -rf /etc/systemd/system/multi-user.target.wants/createbr.service
}

buildimage(){
	INSTANCE_ID=rac_template
	mkdir -p /var/lib/machines/$INSTANCE_ID/etc/yum.repos.d/
	curl -L -o /var/lib/machines/$INSTANCE_ID/etc/yum.repos.d/public-yum-ol7.repo http://yum.oracle.com/public-yum-ol7.repo
	yum -c /var/lib/machines/$INSTANCE_ID/etc/yum.repos.d/public-yum-ol7.repo -y --nogpg --installroot=/var/lib/machines/$INSTANCE_ID install systemd openssh openssh-server passwd yum sudo oraclelinux-release vim-minimal iproute initscripts iputils

	mkdir -p /var/lib/machines/$INSTANCE_ID/root/.ssh
	cp ${ansible_ssh_private_key_file}.pub /var/lib/machines/$INSTANCE_ID/root/.ssh/authorized_keys
	chmod 700 /var/lib/machines/$INSTANCE_ID/root/.ssh 
	chmod 600 /var/lib/machines/$INSTANCE_ID/root/.ssh/*
	
	sed -i 's/^#PermitRootLogin yes/PermitRootLogin yes/' /var/lib/machines/$INSTANCE_ID/etc/ssh/sshd_config
	
	cp --remove-destination /var/lib/machines/$INSTANCE_ID/usr/lib/systemd/system/sshd.service /var/lib/machines/$INSTANCE_ID/etc/systemd/system/multi-user.target.wants/sshd.service
	
	SEGMENT=`echo $NSPAWNSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	NUM=`expr $BASE_IP - 1`
	IP="${SEGMENT}$NUM"	
	mkdir -p /var/lib/machines/$INSTANCE_ID/etc/sysconfig/network-scripts
	cat << EOF > /var/lib/machines/$INSTANCE_ID/etc/sysconfig/network-scripts/ifcfg-host0
DEVICE=host0
TYPE=Ethernet
IPADDR=$IP
GATEWAY=${SEGMENT}1
NETMASK=255.255.255.0
ONBOOT=yes
BOOTPROTO=static
NM_CONTROLLED=no
DELAY=0
EOF

	cat << EOF > /var/lib/machines/$INSTANCE_ID/etc/resolv.conf
nameserver 8.8.8.8
EOF

	cat << EOF > /var/lib/machines/$INSTANCE_ID/etc/systemd/system/multi-user.target.wants/procremount.service
[Unit]
Description=proc_remount
Requires=network.target
Before=network.target remote-fs.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/mount /proc/sys -o rw,remount,bind
ExecStartPost=-/sbin/sysctl -p
User=root
Group=root
[Install]
WantedBy=multi-user.target
EOF

	chmod 644 /var/lib/machines/$INSTANCE_ID/etc/systemd/system/multi-user.target.wants/procremount.service

	touch /var/lib/machines/$INSTANCE_ID/etc/sysconfig/network

	systemd-machine-id-setup --root=/var/lib/machines/$INSTANCE_ID
	machinectl start $INSTANCE_ID
	sleep 20s
	
	/usr/bin/ssh -o StrictHostKeyChecking=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ansible_ssh_private_key_file} root@$IP  "yum -y install selinux-policy firewalld filesystem $PreInstallRPM"

	machinectl poweroff $INSTANCE_ID
	sleep 20s

	rm -rf /var/lib/machines/$INSTANCE_ID/home/oracle
	rm -rf /var/lib/machines/$INSTANCE_ID/var/spool/mail/oracle
			
}

replaceinventory(){
	echo ""
}

get_External_IP(){
	get_Internal_IP $*	
}

get_Internal_IP(){
	if [ "$1" = "storage" ]; then
		NUM=`expr $BASE_IP`
	else
		NUM=`expr $BASE_IP + $1`
	fi
	SEGMENT=`echo $NSPAWNSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	Internal_IP="${SEGMENT}$NUM"

	echo $Internal_IP	
}


source ./common_menu.sh




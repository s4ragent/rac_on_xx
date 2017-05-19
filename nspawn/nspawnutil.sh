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
	mkdir -p /var/lib/machines/$INSTANCE_ID/root/.ssh
	cp ${ansible_ssh_private_key_file}.pub /var/lib/machines/$INSTANCE_ID/root/.ssh/authorized_keys
	chmod 700 /var/lib/machines/$INSTANCE_ID/root/.ssh 
	chmod 600 /var/lib/machines/$INSTANCE_ID/root/.ssh/*
	
	sed -i 's/^#PermitRootLogin yes/PermitRootLogin yes/' /var/lib/machines/$INSTANCE_ID/etc/ssh/sshd_config
	cp /var/lib/machines/$INSTANCE_ID/usr/lib/systemd/system/sshd.service /var/lib/machines/$INSTANCE_ID/etc/systemd/system/multi-user.target.wants/sshd.service
	
	SEGMENT=`echo $NSPAWNSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
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

 #   	(docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /boot/:/boot:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro $StorageOps $IMAGE /sbin/init)

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP

	#docker exec ${NODENAME} useradd $ansible_ssh_user                                                                                                          
	#docker exec ${NODENAME} bash -c "echo \"$ansible_ssh_user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/$ansible_ssh_user"
	#docker exec ${NODENAME} bash -c "mkdir /home/$ansible_ssh_user/.ssh"
	#docker cp ${ansible_ssh_private_key_file}.pub ${NODENAME}:/home/$ansible_ssh_user/.ssh/authorized_keys
	#docker exec ${NODENAME} bash -c "chown -R ${ansible_ssh_user} /home/$ansible_ssh_user/.ssh && chmod 700 /home/$ansible_ssh_user/.ssh && chmod 600 /home/$ansible_ssh_user/.ssh/*"
	systemd-machine-id-setup --root=/var/lib/machines/$INSTANCE_ID
	machinectl start $INSTANCE_ID
   
#   docker exec $NODENAME sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
	#docker exec ${NODENAME} systemctl start sshd
	#docker exec ${NODENAME} systemctl enable sshd
#	docker exec $NODENAME systemctl start NetworkManager
#	docker exec $NODENAME systemctl enable NetworkManager
}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	
	HasNework=`brctl show | grep $BRNAME | wc -l`
	if [ "$HasNework" = "0" ]; then
		brctl addbr $BRNAME
		
		SEGMENT=`echo $NSPAWNSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
		ip addr add dev $BRNAME ${SEGMENT}1/24
		ip link set up dev $BRNAME
		
		iptables -t nat -N $BRNAME
		iptables -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j $BRNAME
		iptables -t nat -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j $BRNAME
		iptables -t nat -A POSTROUTING -s ${SEGMENT}0/24 ! -o $BRNAME -j MASQUERADE
		iptables -t nat -A $BRNAME -i $BRNAME -j RETURN
		iptables -I FORWARD -i $BRNAME -o $BRNAME -j ACCEPT
		iptables -I FORWARD -i $BRNAME ! -o $BRNAME -j ACCEPT
		iptables -I FORWARD -o $BRNAME -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	fi
	
	if [  ! -e $ansible_ssh_private_key_file ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi

	if [  ! -e /var/lib/machines/rac_template ] ; then
		buildimage
	fi
	
	nspawncmd=`which systemd-nspawn`
	mkdir -p /etc/systemd/system/systemd-nspawn@.service.d
	if [  ! -e /etc/systemd/system/systemd-nspawn@.service.d/override.conf ] ; then
			cat << EOF  > /etc/systemd/system/systemd-nspawn@.service.d/override.conf
[Service]
ExecStart=
ExecStart=$nspawncmd --quiet --keep-unit --boot --link-journal=try-guest --machine=%I --network-bridge=$BRNAME --bind-ro=/boot
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


	
	
	
	
	
	STORAGEIP=`get_Internal_IP storage`
	run "storage" $STORAGEIP 0 "storage"
	
	common_update_all_yml "STORAGE_SERVER: $STORAGEIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_Internal_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODEIP $i "dbserver"
	done
	
	sleep 10s
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
	
	machinectl stop storage
	ip link del vb-storage
	for i in `seq 1 100`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		machinectl stop ${NODENAME}
		ip link del vb-${NODENAME}
	done
	
	rm -rf /var/lib/machines/*
	ip link set $BRNAME down
	brctl delbr $BRNAME
  	
	rm -rf /tmp/$CVUQDISK
}

buildimage(){
	INSTANCE_ID=rac_template
	mkdir -p /var/lib/machines/$INSTANCE_ID/etc/yum.repos.d/
	curl -L -o /var/lib/machines/$INSTANCE_ID/etc/yum.repos.d/public-yum-ol7.repo http://yum.oracle.com/public-yum-ol7.repo
	yum -c /var/lib/machines/$INSTANCE_ID/etc/yum.repos.d/public-yum-ol7.repo -y --nogpg --installroot=/var/lib/machines/$INSTANCE_ID install systemd openssh openssh-server passwd yum sudo oraclelinux-release vim-minimal iproute initscripts iputils
	touch /var/lib/machines/$INSTANCE_ID/etc/sysconfig/network
	setcap cap_net_raw,cap_net_admin+p /var/lib/machines/$INSTANCE_ID/usr/bin/ping
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




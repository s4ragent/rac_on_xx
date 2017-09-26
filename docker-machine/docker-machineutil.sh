#!/bin/bash

VIRT_TYPE="docker-machine"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){

	NODENAME=$1
	IP=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	
	IsDeviceMapper=`docker info | grep devicemapper | grep -v grep | wc -l`

#	if [ "$IsDeviceMapper" != "0" ]; then
	eval $(docker-machine env $NODENAME)
	docker-machine ssh $NODENAME sudo mkdir -p $DOCKER_VOLUME_PATH/$NODENAME
	docker-machine ssh $NODENAME sudo chmod -R 777  $DOCKER_VOLUME_PATH
	StorageOps="-v $DOCKER_VOLUME_PATH/$NODENAME:/u01:rw"
#     		#DeviceMapper_BaseSize=$DeviceMapper_BaseSize
#	else
      		#DeviceMapper_BaseSize=""
#      		StorageOps=""
#	fi
#   
#    INSTANCE_ID=$(docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/media:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro $DeviceMapper_BaseSize $IMAGE /sbin/init)


	docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /boot/:/boot:ro  $StorageOps $IMAGE /sbin/init
	INSTANCE_ID=$NODENAME

#docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /boot/:/boot:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro $StorageOps $IMAGE /sbin/init
	INSTANCE_ID=$NODENAME

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP

	docker exec ${NODENAME} useradd $ansible_ssh_user                                                                                                          
	docker exec ${NODENAME} bash -c "echo \"$ansible_ssh_user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/$ansible_ssh_user"
	docker exec ${NODENAME} bash -c "mkdir /home/$ansible_ssh_user/.ssh"
	docker cp ${ansible_ssh_private_key_file}.pub ${NODENAME}:/home/$ansible_ssh_user/.ssh/authorized_keys
	docker exec ${NODENAME} bash -c "chown -R ${ansible_ssh_user} /home/$ansible_ssh_user/.ssh && chmod 700 /home/$ansible_ssh_user/.ssh && chmod 600 /home/$ansible_ssh_user/.ssh/*"

	sleep 10
   
#   docker exec $NODENAME sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
	docker exec ${NODENAME} systemctl start sshd
	docker exec ${NODENAME} systemctl enable sshd
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
	
	if [  ! -e $ansible_ssh_private_key_file ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi

 docker-machine create $DOCKERMACHINE_OPS storage
	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		docker-machine create $DOCKERMACHINE_OPS $NODENAME
	done
	
	setup_host_vxlan

	STORAGEIP=`get_Internal_IP storage`
	run "storage" $STORAGEIP 0 "storage"
	
	common_update_all_yml "STORAGE_SERVER: $STORAGEIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_Internal_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODEIP $i "dbserver"
	done
	
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

	hostlist=`docker-machine ls -q`
	for host in $hostlist;
	do
		docker-machine rm -y $host
	done
	
	sudo ip link set vxlan100 down
	sudo ip link del vxlan100 
  	
	rm -rf /tmp/$CVUQDISK
}

buildimage(){
	docker build -t $IMAGE --no-cache=true ./images/OEL7
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
	SEGMENT=`echo $DOCKERSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	Internal_IP="${SEGMENT}$NUM"

	echo $Internal_IP	
}


setup_host_vxlan(){
	hostlist="localhost `docker-machine ls -q`"
	
	cnt=0
	for src in $hostlist;
	do
		

		SEGMENT=`echo $DOCKERSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.'`
		if [ "$src" = "localhost" ]; then
			sudo ip link add vxlan100 type vxlan id 100 ttl 4 dev $LOCALMACHINE_VXLAN_DEV
			sudo ip link set vxlan100 up
			bridgecmd="sudo $LOCALMACHINE_BRIDGE_CMD"
			
			sudo ip addr add ${SEGMENT}${cnt}.254/16 dev vxlan100
			
		else

			docker-machine ssh $src docker network create -d bridge --subnet=$DOCKERSUBNET --gateway="${SEGMENT}${cnt}.254" --opt "com.docker.network.bridge.name"=$BRNAME $BRNAME
			docker-machine ssh $src sudo ip link add vxlan100 type vxlan id 100 ttl 4 dev $DOCKERMACHINE_VXLAN_DEV
			docker-machine ssh $src sudo ip link set dev vxlan100 master $BRNAME
			docker-machine ssh $src sudo ip link set vxlan100 up	
			bridgecmd="docker-machine ssh $src sudo $DOCKERMACHINE_BRIDGE_CMD"
				
		fi
	
		for dst in $hostlist;
		do
			if [ "$src" = "$dst" ]; then
				continue;
			fi
			
			if [ "$dst" = "localhost" ]; then
				dstip=`ip addr show $LOCALMACHINE_VXLAN_DEV | grep "inet " | awk -F '[/ ]' '{print $6}'`
			else
				dstip=`docker-machine ip $dst`
			fi
			
			$bridgecmd fdb append 00:00:00:00:00:00 dev vxlan100 dst $dstip
		done
	
		cnt=`expr $cnt + 1`
	
	done
}

source ./common_menu.sh



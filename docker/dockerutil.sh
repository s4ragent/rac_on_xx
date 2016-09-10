#!/bin/bash

VIRT_TYPE="docker"

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
#		mkdir -p $DOCKER_VOLUME_PATH/$NODENAME
#		StorageOps="-v $DOCKER_VOLUME_PATH/$NODENAME:/u01:rw"
#     		#DeviceMapper_BaseSize=$DeviceMapper_BaseSize
#	else
#      		#DeviceMapper_BaseSize=""
#      		StorageOps=""
#	fi
#   
#    INSTANCE_ID=$(docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/media:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro $DeviceMapper_BaseSize $IMAGE /sbin/init)
	mkdir -p $DOCKER_VOLUME_PATH/$NODENAME
	StorageOps="-v $DOCKER_VOLUME_PATH/$NODENAME:/u01:rw"

    	INSTANCE_ID=$(docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/$MEDIA_PATH:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro $StorageOps $IMAGE /sbin/init)

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP

	docker exec ${NODENAME} useradd $ansible_ssh_user                                                                                                          
	docker exec ${NODENAME} bash -c "echo \"$ansible_ssh_user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/opc"
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
	
	HasNework=`docker network ls | grep racbr | wc -l`
	if [ "$HasNework" = "0" ]; then
		docker network create -d bridge --subnet=$DOCKERSUBNET $BRNAME
	fi
	
	if [  ! -e $ansible_ssh_private_key_file ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi
   
	SEGMENT=`echo $DOCKERSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`

	NFSIP="${SEGMENT}$BASE_IP"
	run "nfs" $NFSIP 0 "nfs"
	
	common_update_all_yml "NFS_SERVER: $NFSIP"
	
	for i in `seq 1 $nodecount`;
	do
		NUM=`expr $BASE_IP + $i`
		NODEIP="${SEGMENT}$NUM"
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODEIP $i "dbserver"
	done
	
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
	common_stopall $*
   	common_deleteall $*
	#### VIRT_TYPE specific processing ###
	if [ -n "$ansible_ssh_private_key_file" ]; then
   		rm -rf ${ansible_ssh_private_key_file}*
	fi

	if [ -n "$DOCKER_VOLUME_PATH" ]; then
   		rm -rf $DOCKER_VOLUME_PATH
	fi	

	docker network rm $BRNAME
   
}

buildimage(){
	docker build -t $IMAGE --no-cache=true ./images/OEL7
}
replaceinventory(){
	echo ""
}

source ./common_menu.sh



#!/bin/bash

####common VIRT_TYPE specific value ################
VIRT_TYPE="gce"

cd ..
source ./commonutil.sh

#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 disksize $3 nodenumber $4 hostgroup#####
run(){
	NODENAME=$1
	DISKSIZE=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID=$NODENAME
	CREATE_RESULT=$(gcloud compute instances create $NODENAME $INSTANCE_TYPE_OPS --can-ip-forward --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" $INSTANCE_OPS --boot-disk-type "pd-standard" --boot-disk-device-name $NODENAME --boot-disk-size $DISKSIZE --zone $ZONE | tail -n 1)

	External_IP=`get_External_IP $INSTANCE_ID`
	Internal_IP=`get_Internal_IP $INSTANCE_ID`
	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_all_yml
	common_update_ansible_inventory $NODENAME $External_IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	
	gcloud compute instances add-metadata $INSTANCE_ID --metadata-from-file ssh-keys=${ansible_ssh_private_key_file}.pub --zone $ZONE

	echo $Internal_IP

}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	
	if [  ! -e ${ansible_ssh_private_key_file} ] ; then
		#ssh-keygen -t rsa -P "" -f $sudokey -C $sudoer
		ssh-keygen -t rsa -P "" -f tempkey -C $ansible_ssh_user
		echo "$ansible_ssh_user:"`cat tempkey.pub` > ${ansible_ssh_private_key_file}.pub
		rm -f tempkey.pub
      		mv -f tempkey ${ansible_ssh_private_key_file}
      		chmod 600 ${ansible_ssh_private_key_file}*
		
	fi
   
	is_create_network=`gcloud compute networks list | grep default | wc -l`
	if [ $is_create_network -eq 0 ] ; then
		gcloud compute networks create default
		gcloud compute firewall-rules create default-allow-icmp --network default --allow icmp --source-ranges 0.0.0.0/0
		gcloud compute firewall-rules create default-allow-ssh --network default --allow tcp:22 --source-ranges 0.0.0.0/0
		gcloud compute firewall-rules create default-allow-internal --network default --allow tcp:0-65535,udp:0-65535,icmp --source-ranges 10.0.0.0/8
	fi

	if [ "${storage_type}" = "nbd" ] ; then
		echo "nostorage"
	else
		STORAGEIP=`run storage $STORAGE_DISK_SIZE 0 storage`
	fi
	
	common_update_all_yml "STORAGE_SERVER: $STORAGEIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODE_DISK_SIZE $i "dbserver"
	done
	
	sleep 180s
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
   
}

replaceinventory(){
	for FILE in $VIRT_TYPE/host_vars/*
	do
		INSTANCE_ID=`echo $FILE | awk -F '/' '{print $3}'`
		External_IP=`get_External_IP $INSTANCE_ID`
		common_replaceinventory $INSTANCE_ID $External_IP
	done
}

get_External_IP(){
	expr "$1" + 1 >/dev/null 2>&1
	if [ $? -lt 2 ]
	then
    		NODENAME="$NODEPREFIX"`printf "%.3d" $1`
	else
    		NODENAME=$1
	fi

	LIST_RESULT=$(gcloud compute instances list  $NODENAME --zones $ZONE | tail -n 1)
	MACHINE_TYPE=`echo $LIST_RESULT | awk '{print $3}'`
	if [ "$MACHINE_TYPE" = "custom" ]; then
		External_IP=`echo $LIST_RESULT | awk '{print $9}'`
	else
		External_IP=`echo $LIST_RESULT | awk '{print $5}'`
	fi
	echo $External_IP	
}

get_Internal_IP(){
	expr "$1" + 1 >/dev/null 2>&1
	if [ $? -lt 2 ]
	then
    		NODENAME="$NODEPREFIX"`printf "%.3d" $1`
	else
    		NODENAME=$1
	fi
	
	LIST_RESULT=$(gcloud compute instances list  $NODENAME --zones $ZONE | tail -n 1)
	MACHINE_TYPE=`echo $LIST_RESULT | awk '{print $3}'`
	if [ "$MACHINE_TYPE" = "custom" ]; then
		Internal_IP=`echo $LIST_RESULT | awk '{print $8}'`
	else
		Internal_IP=`echo $LIST_RESULT | awk '{print $4}'`
	fi
	echo $Internal_IP	
}

source ./common_menu.sh

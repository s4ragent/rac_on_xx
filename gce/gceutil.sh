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
	CREATE_RESULT=$(gcloud compute instances create $NODENAME $INSTANCE_TYPE_OPS --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" $INSTANCE_OPS --boot-disk-type "pd-ssd" --boot-disk-device-name $NODENAME --boot-disk-size $DISKSIZE --zone $ZONE | tail -n 1)
	MACHINE_TYPE=`echo $CREATE_RESULT | awk '{print $3}'`
	if [ "$MACHINE_TYPE" = "custom" ]; then
		External_IP=`echo $CREATE_RESULT | awk '{print $9}'`
		Internal_IP=`echo $CREATE_RESULT | awk '{print $8}'`
	else
		External_IP=`echo $CREATE_RESULT | awk '{print $5}'`
		Internal_IP=`echo $CREATE_RESULT | awk '{print $4}'`
	fi
	
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
   

	NFSIP=`run nfs $STORAGE_DISK_SIZE 0 nfs`
	
	common_update_all_yml "NFS_SERVER: $NFSIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODE_DISK_SIZE $i "dbserver"
	done
	
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
   	common_deleteall $*
	#### VIRT_TYPE specific processing ###
	if [ -n "$ansible_ssh_private_key_file" ]; then
   		rm -rf ${ansible_ssh_private_key_file}*
	fi
   
}

replaceinventory(){
	for FILE in $VIRT_TYPE/host_vars/*
	do
		INSTANCE_NAME=`echo $FILE | awk -F '/' '{print $3}'`
		LIST_RESULT=$(gcloud compute instances list  $INSTANCE_NAME --zones $ZONE | tail -n 1)
		MACHINE_TYPE=`echo $LIST_RESULT | awk '{print $3}'`
		if [ "$MACHINE_TYPE" = "custom" ]; then
			External_IP=`echo $LIST_RESULT | awk '{print $9}'`
		else
			External_IP=`echo $LIST_RESULT | awk '{print $5}'`
		fi
		common_replaceinventory $INSTANCE_NAME $External_IP
	done
}

get_ExternalIP(){
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

get_InternalIP(){
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

#!/bin/bash

####common VIRT_TYPE specific value ################
VIRT_TYPE="azure"

cd ..
source ./commonutil.sh

SUFFIX=`ip a show eth0 | grep ether | awk '{print $2}' | sed -e s/://g`

RG_NAME=RG_${PREFIX}
VNET_NAME=VNET_${PREFIX}
SNET_NAME=SNET_${PREFIX}
SA_NAME=SA_${PREFIX}${SUFFIX}
NSG_NAME=NSG_${PREFIX}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 disksize $3 nodenumber $4 hostgroup#####
run(){
	NODENAME=$1
	DISKSIZE=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID=$NODENAME
	CREATE_RESULT=$(gcloud compute instances create $NODENAME $INSTANCE_TYPE_OPS --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" $INSTANCE_OPS --boot-disk-type "pd-ssd" --boot-disk-device-name $NODENAME --boot-disk-size $DISKSIZE --zone $ZONE | tail -n 1)

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
	

	HasRG=`azure group list | grep $RGNAME | wc -l`
	if [ "$HasRG" = "0" ]; then
		azure group create -n $RG_NAME -l $ZONE
		azure network vnet create -g $RG_NAME -n $VNET_NAME -a $VNET_ADDR -l $ZONE
		azure network vnet subnet create -g $RG_NAME --vnet-name $VNET_NAME -n $SNET_NAME -a $SNET_ADDR

		azure network nsg create -g $RG_NAME -l $ZONE -n $NSG_NAME
		azure network nsg rule create -g $RG_NAME -a $NSG_NAME -n ssh-rule -c Allow -p Tcp -r Inbound -y 100 -f Internet -o '*' -e '*' -u 22
		azure network vnet subnet set -g $RG_NAME -e $VNET_NAME -o $NSG_NAME -n $SNET_NAME
			
		
	fi

	if [  ! -e ${ansible_ssh_private_key_file} ] ; then
		ssh-keygen -t rsa -P "" -f $sudokey
	fi
   

	STORAGEIP=`run storage $STORAGE_DISK_SIZE 0 storage`
	
	common_update_all_yml "STORAGE_SERVER: $STORAGEIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODE_DISK_SIZE $i "dbserver"
	done
	
	sleep 60s
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
		INSTANCE_ID=`echo $FILE | awk -F '/' '{print $3}'`
		External_IP=`get_External_IP $INSTANCE_ID`
		common_replaceinventory $INSTANCE_NAME $External_IP
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

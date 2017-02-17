#!/bin/bash

####common VIRT_TYPE specific value ################
VIRT_TYPE="azure"

cd ..
source ./commonutil.sh

SUFFIX=`ip a show eth0 | grep ether | awk '{print $2}' | sed -e s/://g`

VNET_NAME=vnet_${PREFIX}
SNET_NAME=snet_${PREFIX}
SA_NAME=${PREFIX}${SUFFIX}
NSG_NAME=nsg_${PREFIX}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 disksize $3 nodenumber $4 hostgroup#####
run(){
	NODENAME=$1
	DISKSIZE=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID=$NODENAME
	
	
	result=$(azure network public-ip create -g $RG_NAME  -n ip_${NODENAME} --location $ZONE)
	#result=$(azure vm create -g $RG_NAME -n $NODENAME --nic-name nic_${NODENAME} -i ip_${NODENAME} -o ${SA_NAME} -x data-${NODENAME} -e $DISKSIZE --location $ZONE --os-type Linux $INSTANCE_TYPE_OPS $INSTANCE_OPS --admin-username ${ansible_ssh_user}  --ssh-publickey-file ./${ansible_ssh_private_key_file}.pub --vnet-name $VNET_NAME --vnet-subnet-name $SNET_NAME)
	result=$(azure vm create -g $RG_NAME -n $NODENAME --nic-name nic_${NODENAME} -i ip_${NODENAME} -o ${SA_NAME} --location $ZONE --os-type Linux $INSTANCE_TYPE_OPS $INSTANCE_OPS --admin-username ${ansible_ssh_user}  --ssh-publickey-file ./${ansible_ssh_private_key_file}.pub --vnet-name $VNET_NAME --vnet-subnet-name $SNET_NAME)

	External_IP=`get_External_IP $INSTANCE_ID`
	Internal_IP=`get_Internal_IP $INSTANCE_ID`
	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_all_yml
	common_update_ansible_inventory $NODENAME $External_IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	
	result=$(azure vm disk attach-new $RG_NAME $NODENAME $DISKSIZE --location $ZONE)

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
	

	HasRG=`azure group list | grep $RG_NAME | wc -l`
	if [ "$HasRG" = "0" ]; then
		azure group create -n $RG_NAME -l $ZONE
		azure storage account create ${SA_NAME} --sku-name LRS --kind Storage -g $RG_NAME -l $ZONE
		azure network vnet create -g $RG_NAME -n $VNET_NAME -a $VNET_ADDR -l $ZONE
		azure network vnet subnet create -g $RG_NAME --vnet-name $VNET_NAME -n $SNET_NAME -a $SNET_ADDR

		azure network nsg create -g $RG_NAME -l $ZONE -n $NSG_NAME
		azure network nsg rule create -g $RG_NAME -a $NSG_NAME -n ssh-rule -c Allow -p Tcp -r Inbound -y 100 -f Internet -o '*' -e '*' -u 22
		azure network vnet subnet set -g $RG_NAME -e $VNET_NAME -o $NSG_NAME -n $SNET_NAME
			
		
	fi

	if [  ! -e ${ansible_ssh_private_key_file} ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
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
	if [ -e "$ansible_ssh_private_key_file" ]; then
   		rm -rf ${ansible_ssh_private_key_file}*
		azure group delete -n $RG_NAME  -q
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

	ip_name=ip_${NODENAME}
	External_IP=`azure network public-ip show -g $RG_NAME -n $ip_name | grep "IP Address" | awk '{print $5}'`
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
	
	nic_name=nic_${NODENAME}
	Internal_IP=`azure network nic show -g $RG_NAME -n $nic_name | grep "Private IP address" | awk '{print $6}'`

	echo $Internal_IP
}

source ./common_menu.sh

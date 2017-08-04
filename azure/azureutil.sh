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
	
	result=$(az vm create --location $ZONE $INSTANCE_TYPE_OPS $INSTANCE_OPS --os-type Linux --resource-group $RG_NAME --name $NODENAME --admin-username ${ansible_ssh_user}  --ssh-key-value ./${ansible_ssh_private_key_file}.pub --public-ip-address ip_${NODENAME} --vnet-name $VNET_NAME --subnet $SNET_NAME --storage-sku Standard_LRS)

	External_IP=`get_External_IP $INSTANCE_ID`
	Internal_IP=`get_Internal_IP $INSTANCE_ID`
	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_all_yml
	common_update_ansible_inventory $NODENAME $External_IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	
	result=$(az vm disk attach --resource-group $RG_NAME --vm-name $NODENAME --size-gb $DISKSIZE --sku Standard_LRS --disk disk_${NODENAME} --new)

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
	

	HasRG=`az group list | grep $RG_NAME | wc -l`
	if [ "$HasRG" = "0" ]; then
		az group create -n $RG_NAME -l $ZONE
		az network vnet create -g $RG_NAME -n $VNET_NAME --address-prefix $VNET_ADDR --subnet-name $SNET_NAME --subnet-prefix $SNET_ADDR

		az network nsg create -g $RG_NAME -l $ZONE -n $NSG_NAME
		az network nsg rule create --resource-group $RG_NAME --nsg-name $NSG_NAME --name RuleSSH --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 --access allow
		az network vnet subnet update --resource-group $RG_NAME --vnet-name $VNET_NAME --name $SNET_NAME --network-security-group $NSG_NAME
	fi

	if [  ! -e ${ansible_ssh_private_key_file} ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi
   
	if [ "${storage_type}" = "nfsmulti" ] ; then
				run storage01 $STORAGE_DISK_SIZE 70 storage
				run storage02 $STORAGE_DISK_SIZE 71 storage
				run storage03 $STORAGE_DISK_SIZE 72 storage
	else
		STORAGEIP=`run storage $STORAGE_DISK_SIZE 0 storage`
	common_update_all_yml "STORAGE_SERVER: $STORAGEIP"
	fi
   
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
	fi
   az group delete -n $RG_NAME  -y
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
	External_IP=`az vm show -g $RG_NAME -n $NODENAME -d | grep publicIps | awk -F '"' '{print $4}'`
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
	Internal_IP=`az vm show -g $RG_NAME -n $NODENAME -d | grep privateIps | awk -F '"' '{print $4}'`

	echo $Internal_IP
}

source ./common_menu.sh

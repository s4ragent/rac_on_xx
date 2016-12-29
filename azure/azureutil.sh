#!/bin/bash

####common VIRT_TYPE specific value ################
VIRT_TYPE="azure"

cd ..
source ./commonutil.sh

SUFFIX=`ip a show eth0 | grep ether | awk '{print $2}' | sed -e s/://g`

RG_NAME=rg_${PREFIX}
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
	
	
	azure network public-ip create -g $RG_NAME  -n ip_${NODENAME} --location $ZONE
	
	
	azure vm create -g $rg_name -n $name --nic-name nic_${name} -i ip_${name} -o ${sa_name} -x data-${name} -e $disksize --location $location --os-type Linux --image-urn $image_urn --admin-username $adminuser --vm-size $vmsize --ssh-publickey-file ./${prefix} --vnet-name $vnet_name --vnet-subnet-name $snet_name
}

create_centos(){
	image_urn="OpenLogic:CentOS:7.2:latest"
	name=$1
	vmsize=$2
	disksize=$3
	create_linux $name $vmsize $disksize $image_urn	
}

create_oraclelinux(){
	image_urn="Oracle:Oracle-Linux:7.2:latest"
	name=$1
	vmsize=$2
	disksize=$3
	create_linux $name $vmsize $disksize $image_urn	
}

create_ubuntu(){
	image_urn="canonical:ubuntuserver:16.04.0-LTS:latest"
		name=$1
}

create_oraclelinux_docker(){
		name=$1

}

create_2012(){
		name=$1
}

create_centos_docker(){
		name=$1
}

create_ubuntu_docker(){
		name=$1
}

deleteall(){
	azure group delete -n $rg_name  -q
	rm -rf ./${prefix}*
}

delete(){
	name=$1
	azure vm delete  -g $rg_name -n $name -q
	azure network nic delete -g $rg_name -n nic_${name} -q
	azure network public-ip delete -g $rg_name  -n ip_${name} -q
}

stop(){
	name=$1
	azure vm deallocate -g $rg_name -n $name
}

ssh2(){
name=$1
pip=`get_External_IP $name`


if [ "$2" != "" ]; then
	if [ "$3" != "" ]; then
		if [ "$4" != "" ]; then
			ssh -i ./${prefix} -l $adminuser -g -L $2:$3:$4 $pip  
		else
			ssh -i ./${prefix} -l $adminuser -g-L $2:127.0.0.1:$3 $pip	
		fi
	else
		ssh -i ./${prefix} -l $adminuser -g -L $2:127.0.0.1:$2 $pip
	fi
else
	ssh -i ./${prefix} -l $adminuser $pip
fi

}


case "$1" in
  "create_first" ) shift;create_first $*;;
  "ssh2" ) shift;ssh2 $*;;
  "create_2012" ) shift;create_2012 $*;;
  "create_2016" ) shift;create_2016 $*;;
  "create_oraclelinux" ) shift;create_oraclelinux $*;;
  "create_centos" ) shift;create_centos $*;;
  "create_ubuntu" ) shift;create_ubuntu $*;;
  "create_centos_docker" ) shift;create_centos_docker $*;;
  "create_ubuntu_docker" ) shift;create_ubuntu_docker $*;;
  "create_oraclelinux_docker" ) shift;create_oraclelinux_docker $*;;
  "deleteall" ) shift;deleteall $*;;
  "delete" ) shift;delete $*;;
  "stop" ) shift;stop $*;;
  "get_External_IP" ) shift;get_External_IP $*;;
esac


	External_IP=`get_External_IP $INSTANCE_ID`
	Internal_IP=`get_Internal_IP $INSTANCE_ID`
	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_all_yml
	common_update_ansible_inventory $NODENAME $External_IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	


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
		azure storage account create ${SA_NAME} --sku-name LRS --kind Storage -g $RG_NAME -l $ZONE
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
		azure group delete -n $RG_NAME  -q
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
	Internal_IP=`azure network nic show -g $RG_NAME -n $nic_name | grep "Private IP Address" | awk '{print $5}'`

	echo $Internal_IP
}

source ./common_menu.sh

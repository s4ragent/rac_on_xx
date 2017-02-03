#!/bin/bash

####common VIRT_TYPE specific value ################
VIRT_TYPE="ec2"

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

	vpcid=`aws ec2 describe-vpcs --region $REGION --filters "Name=is-default,Values=true" --query "Vpcs[].VpcId" --output text`
        sgid=`aws ec2 describe-security-groups --region $REGION --group-names $PREFIX --query "SecurityGroups[].GroupId" --output text`
	subnetid=`aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$vpcid" --filters "Name=availabilityZone,Values=${REGION}a" --output text --query "Subnets[].SubnetId"`
        
	DeviceJson="[{\"DeviceName\":\"${data_disk_dev}\",\"Ebs\":{\"VolumeSize\":${2},\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}}]"
	
	
	
	
	InstanceId=$(aws ec2 run-instances --region $REGION $INSTANCE_OPS $INSTANCE_TYPE_OPS --key-name $PREFIX --subnet-id $subnetid --security-group-ids $sgid --block-device-mappings $DeviceJson --count 1 --query "Instances[].InstanceId" --output text)
	aws ec2 create-tags --region $REGION --resources $InstanceId --tags Key=NODENAME,Value=$NODENAME
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

	vpcid=`aws ec2 describe-vpcs --region $REGION --filters "Name=is-default,Values=true" --query "Vpcs[].VpcId" --output text`
        sgid=`aws ec2 describe-security-groups --region $REGION --group-names $PREFIX --query "SecurityGroups[].GroupId" --output text`
 
 	if [  ! -n ${sgid} ] ; then
	        sgid=`aws ec2 create-security-group --region $REGION --group-name ${PREFIX} --description "Security group for SSH access" --vpc-id $vpcid --query "GroupId" --output text`
		aws ec2 authorize-security-group-ingress --region $REGION --group-name ${PREFIX} --protocol all --source-group $sgid
		aws ec2 authorize-security-group-ingress --region $REGION --group-name ${PREFIX} --protocol tcp --port 22 --cidr 0.0.0.0/0
	fi
 
        if [  ! -e ${ansible_ssh_private_key_file} ] ; then
	        aws ec2 create-key-pair --region $REGION --key-name $ansible_ssh_private_key_file  --query 'KeyMaterial' --output text > $ansible_ssh_private_key_file
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
		common_replaceinventory $INSTANCE_ID $External_IP
	done
}

get_External_IP(){
	if [[ $1 = i-*  ]]; then
		INSTANCE_ID=$1
	else
		expr "$1" + 1 >/dev/null 2>&1
		if [ $? -lt 2 ]
		then
    			NODENAME="$NODEPREFIX"`printf "%.3d" $1`
		else
    			NODENAME=$1
		fi
		
		
		INSTANCE_ID=`aws ec2 describe-tags --region $REGION --filters "Name=resource-type,Values=instance" "Name=key,Values=NODENAME" "Name=value,Values=$NODENAME" --query "Tags[].ResourceId" --output text`
	fi


	External_IP=`aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query "Reservations[].Instances[].PublicIpAddress" --output text`
	echo $External_IP	
}

get_Internal_IP(){
	if [[ $1 = i-*  ]]; then
		INSTANCE_ID=$1
	else
		expr "$1" + 1 >/dev/null 2>&1
		if [ $? -lt 2 ]
		then
    			NODENAME="$NODEPREFIX"`printf "%.3d" $1`
		else
    			NODENAME=$1
		fi
		
		
		INSTANCE_ID=`aws ec2 describe-tags --region $REGION --filters "Name=resource-type,Values=instance" "Name=key,Values=NODENAME" "Name=value,Values=$NODENAME" --query "Tags[].ResourceId" --output text`
	fi

	Internal_IP=`aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query "Reservations[].Instances[].PrivateIpAddress" --output text`
	echo $Internal_IP	
}

source ./common_menu.sh

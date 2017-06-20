#!/bin/bash

####common VIRT_TYPE specific value ################
VIRT_TYPE="efs"

cd ..
source ./commonutil.sh

#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 disksize $3 nodenumber $4 hostgroup#####
run(){
	NODENAME=$1
	INSTANCE_ID=$2
	NODENUMBER=$3
	HOSTGROUP=$4

	aws ec2 create-tags --region $REGION --resources $INSTANCE_ID --tags Key=NODENAME,Value=$NODENAME
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

	if [  ! -e ${ansible_ssh_private_key_file} ] ; then
	aws ec2 create-key-pair --region $REGION --key-name $ansible_ssh_private_key_file  --query 'KeyMaterial' --output text > $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi

ansible-playbook -i localhost, $VIRT_TYPE/efs.yml --tags create --extra-vars "nodecount=$nodecount" -vvv

	instanceid=`aws ec2 describe-instances --filters "Name=tag:Name,Values=${PREFIX}-storage" "Name=instance-state-name,Values=pending,running" --region $REGION --query "Reservations[].Instances[].InstanceId" --output text`
 filesystemid=`aws efs describe-file-systems --region $REGION --creation-token ${PREFIX}-EFS --query "FileSystems[].FileSystemId" --output text`

#STORAGEIP=`run storage $instanceid 0 storage`
#STORAGEIP=`aws efs describe`
	common_update_all_yml "STORAGE_SERVER: ${filesystemid}.efs.${REGION}.amazonaws.com"

	instanceids=`aws ec2 describe-instances --filters "Name=tag:Name,Values=${PREFIX}-dbserver" "Name=instance-state-name,Values=pending,running" --region $REGION --query "Reservations[].Instances[].InstanceId" --output text`

cnt=1
for id in $instanceids
do
	NODENAME="$NODEPREFIX"`printf "%.3d" $cnt`
	run $NODENAME $id $cnt "dbserver"
	cnt=`expr $cnt + 1`
done

ansible-playbook -i $VIRT_TYPE $VIRT_TYPE/route53.yml --tags create

#	for i in `seq 1 $nodecount`;
#	do
#		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
#		run $NODENAME $NODE_DISK_SIZE $i "dbserver"
#	done
	
#	sleep 300s






#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
	ansible-playbook -i $VIRT_TYPE $VIRT_TYPE/route53.yml --tags delete

   	common_deleteall $*
	#### VIRT_TYPE specific processing ###
	if [ -e "$ansible_ssh_private_key_file" ]; then
   		rm -rf ${ansible_ssh_private_key_file}*
		aws ec2 delete-key-pair --region $REGION --key-name $ansible_ssh_private_key_file
	fi


   	
ansible-playbook -i localhost, $VIRT_TYPE/efs.yml --tags delete

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

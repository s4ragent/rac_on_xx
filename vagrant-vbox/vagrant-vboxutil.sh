#!/bin/bash

VIRT_TYPE="vagrant-vbox"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){
sleep 1s
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
		cp ~/.vagrant.d/insecure_private_key $ansible_ssh_private_key_file
		ssh-keygen -y -f $ansible_ssh_private_key_file > ${ansible_ssh_private_key_file}.pub
		chmod 600 ${ansible_ssh_private_key_file}*
	fi
	
	STORAGEIP=`get_Internal_IP storage`
	arg_string="storage,$STORAGEIP,storage,0,storage"
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_Internal_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		arg_string="$arg_string $NODENAME,$NODEIP,$NODENAME,$i,dbserver"
	done
	
	common_create_inventry "STORAGE_SERVER: $STORAGEIP" "$arg_string"
	
	common_create_box $nodecount
	
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
 common_deleteall $*
	cd $VIRT_TYPE
	vagrant destroy -f
  	
	rm -rf /tmp/$CVUQDISK
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
	SEGMENT=`echo $VBOXSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	Internal_IP="${SEGMENT}$NUM"

	echo $Internal_IP	
}

source ./common_menu.sh



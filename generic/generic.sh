#!/bin/bash

VIRT_TYPE="generic"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	
	NODENUMBER=0
	for node in $NODELIST;
	do
		NODENAME=`echo $node | awk -F ',' '{print $1}' `
		IP=`echo $node | awk -F ',' '{print $2}' `
		HOSTGROUP=`echo $node | awk -F ',' '{print $3}' `
		INSTANCE_ID=$NODENAME
		
		common_update_ansible_inventory "$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP"
		NODENUMBER=`expr $NODENUMBER + 1`
	done


#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
 common_deleteall $*
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
	SEGMENT=`echo $KVMSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	Internal_IP="${SEGMENT}$NUM"

	echo $Internal_IP	
}


source ./common_menu.sh




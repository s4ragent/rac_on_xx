#!/bin/bash

VIRT_TYPE="generic"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){

	common_create_inventry "STORAGE_SERVER: $STORAGEIP" "$NODELIST"


#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
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




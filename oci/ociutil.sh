#!/bin/bash

VIRT_TYPE="oci"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	common_create_inventry "" "$NODELIST"	
}

deleteall(){
 common_deleteall $*
	rm -rf /tmp/$CVUQDISK

}

replaceinventory(){
	echo ""
}

get_External_IP(){
	expr "$1" + 1 >/dev/null 2>&1
	if [ $? -lt 2 ]
	then
    		NODENAME="$NODEPREFIX"`printf "%.3d" $1`
	else
    		NODENAME=$1
	fi
	
	if [ "$1" = "storage" ]; then
		External_IP=`cat storage.inventory | grep $NODENAME | awk -F "=" '{print $2}'`
	else
		External_IP=`cat dbserver.inventory | grep $NODENAME | awk -F "=" '{print $2}'`
	fi
	
	echo $External_IP	
}

get_Internal_IP(){
	
}

source ./common_menu.sh




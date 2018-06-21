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
	get_Internal_IP $*	
}

get_Internal_IP(){
	if [ "$1" = "storage" ]; then
		cat storage.inventory | grep node001 | awk -F "=" '{print $2}'
	else
		cat dbserver.inventory | grep node001 | awk -F "=" '{print $2}'
	fi
	

	echo $Internal_IP	
}

source ./common_menu.sh




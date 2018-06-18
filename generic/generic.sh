#!/bin/bash

VIRT_TYPE="generic"

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

source ./common_menu.sh




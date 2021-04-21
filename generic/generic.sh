#!/bin/bash

VIRT_TYPE="generic"

cd ..
source ./commonutil.sh

common_addDbServer(){
	if [ "$1" = "" ]; then
		echo "INPUT NUMBERS OF DBSERVERS"
		read nodecount
	else
		nodecount=$1
	fi

        for i in `seq 1 $nodecount`;
        do
                NODENAME="$NODEPREFIX"`printf "%.3d" $i`
                echo "INPUT DBSERVER#$i IP"
                read External_IP
                common_update_ansible_inventory $NODENAME $External_IP $NODENAME $i dbserver
        done    
}

common_addStorage(){		
	if [ "$storage_type" = "nfs" -o "$storage_type" = "iscsi" ]; then
		echo "INPUT STORAGE_IP"
		read STORAGEExtIP
		common_update_ansible_inventory storage001 $STORAGEExtIP storage001 0 storage
	fi
}

common_addClient(){
        echo "INPUT CLIENT_IP"
        read ClientExtIP
	common_update_ansible_inventory client001 $ClientExtIP client001 70 client
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
                External_IP=`cat $VIRT_TYPE/storage.inventory | grep $NODENAME | awk -F "=" '{print $2}'`
        else
                External_IP=`cat $VIRT_TYPE/dbserver.inventory | grep $NODENAME | awk -F "=" '{print $2}'`
        fi
        
        echo $External_IP       
}

source ./common_menu.sh


#!/bin/bash

VIRT_TYPE="generic"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
common_runonly(){
        echo "INPUT STORAGE_IP"
        read STORAGEExtIP
        common_update_all_yml "STORAGE_SERVER: $STORAGEExtIP"
        common_update_ansible_inventory storage001 $STORAGEExtIP storage001 0 storage
        
        echo "INPUT NUMBERS OF DBSERVERS"
        read nodecount
        
        for i in `seq 1 $nodecount`;
        do
                NODENAME="$NODEPREFIX"`printf "%.3d" $i`
                echo "INPUT DBSERVER#$i IP"
                read External_IP
                common_update_ansible_inventory $NODENAME $External_IP $NODENAME $i dbserver
        done    

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


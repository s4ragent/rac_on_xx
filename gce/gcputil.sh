#!/bin/bash

##common user specific value #######################
sudoer="opc"
sudokey="raconxx"
####################################################
#### docker user specific value  ###################
#ZONE="us-west1-b"
ZONE="asia-east1-c"
#MACHINE_TYPE="n1-highmem-2"
MACHINE_TYPE="n1-standard-1"
NODE_DISK_SIZE="50GB"
STORAGE_DISK_SIZE="200GB"
####################################################
####common VIRT_TYPE specific value ################
VIRT_TYPE="gce"
DELETE_CMD="gcloud compute instances delete"
DELETE_CMD_OPS="--zone $ZONE -q"
START_CMD="gcloud compute instances start"
START_CMD_OPS="--zone $ZONE -q"
STOP_CMD="gcloud compute instances stop"
STOP_CMD_OPS="--zone $ZONE -q"
INSTALL_OPS="-ignoreSysprereqs -ignorePrereq"
####################################################
####google cloud  system  specific value ##################
IMAGE="centos-7"
####################################################

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
	CREATE_RESULT=$(gcloud compute instances create $NODENAME --machine-type $MACHINE_TYPE --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image $IMAGE --boot-disk-type "pd-ssd" --boot-disk-device-name $NODENAME --boot-disk-size $DISKSIZE --zone $ZONE | tail -n 1)
	External_IP=`echo $CREATE_RESULT | awk '{print $5}'`
	Internal_IP=`echo $CREATE_RESULT | awk '{print $4}'`
	
	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_all_yml
	common_update_ansible_inventory $NODENAME $External_IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	
	gcloud compute instances add-metadata $INSTANCE_ID --metadata-from-file ssh-keys=${sudokey}.pub --zone $ZONE
	
	
	
	
	
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
	
	if [  ! -e $sudokey ] ; then
		#ssh-keygen -t rsa -P "" -f $sudokey -C $sudoer
		ssh-keygen -t rsa -P "" -f tempkey -C $sudoer
		echo "$sudoer:"`cat tempkey.pub` > ${sudokey}.pub
		rm -f tempkey.pub
      mv -f tempkey ${sudokey}
      chmod 600 ${sudokey}*
	fi
   

	NFSIP=`run nfs $STORAGE_DISK_SIZE 0 nfs`
	
	common_update_all_yml "NFS_SERVER: $NFSIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODE_DISK_SIZE $i "dbserver"
	done
	
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

runall(){
	runonly $*
	execansible rac.yml
}

execansible(){
   ansible-playbook -f 64 -T 600 -i $VIRT_TYPE $*
}

deleteall(){
	common_stopall $*
   	common_deleteall $*
   
	#### VIRT_TYPE specific processing ###
	rm -rf ${sudokey}*
}

stop(){ 
	common_stop $*
}

stopall(){
	common_stopall $*
}

start(){ 
	common_start $*
}

startall(){
	common_startall $*
}

replaceinventory(){
	for FILE in $VIRT_TYPE/host_vars/*
	do
		INSTANCE_NAME=`echo $FILE | awk -F '/' '{print $3}'`
		LIST_RESULT=$(gcloud compute instances list  $INSTANCE_NAME --zones $ZONE | tail -n 1)
		External_IP=`echo $LIST_RESULT | awk '{print $5}'`
		common_replaceinventory $INSTANCE_NAME $External_IP
	done
}

heatrun(){
for i in `seq 1 $2`
do
    LOG="`date "+%Y%m%d-%H%M%S"`.log"
    deleteall >$LOG  2>&1
    STARTTIME=`date "+%Y%m%d-%H%M%S"`
    runall $1 >>$LOG  2>&1
    echo "START $STARTTIME" >>$LOG
    echo "END `date "+%Y%m%d-%H%M%S"`" >>$LOG
done
}

case "$1" in
  "execansible" ) shift;execansible $*;;
  "replaceinventory" ) shift;replaceinventory $*;;
  "runonly" ) shift;runonly $*;;
  "runall" ) shift;runall $*;;
  "run" ) shift;run $*;;
  "startall" ) shift;startall $*;;
  "start" ) shift;start $*;;
  "delete" ) shift;delete $*;;
  "deleteall" ) shift;deleteall $*;;
  "stop" ) shift;stop $*;;
  "stopall" ) shift;stopall $*;;
  "heatrun") shift;heatrun $*;;
esac

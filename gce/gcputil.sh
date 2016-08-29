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
NODE_DISK_SIZE="30GB"
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
	
    CREATE_RESULT=$(gcloud compute instances create $NODENAME --machine-type $MACHINE_TYPE --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image $IMAGE --boot-disk-type "pd-ssd" --boot-disk-device-name $NODENAME --boot-disk-size $DISKSIZE --zone $ZONE | tail -n 1)

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
#	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP

cat $CREATE_RESULT

}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	
	HasNework=`docker network ls | grep racbr | wc -l`
	if [ "$HasNework" = "0" ]; then
		docker network create -d bridge --subnet=$DOCKERSUBNET $BRNAME
	fi
	
	if [  ! -e $sudokey ] ; then
		ssh-keygen -t rsa -P "" -f $sudokey
		chmod 600 ${sudokey}*
	fi
   
	SEGMENT=`echo $DOCKERSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`

	NFSIP="${SEGMENT}$BASE_IP"
	run "nfs" $NFSIP 0 "nfs"
	
	common_update_all_yml "NFS_SERVER: $NFSIP"
	
	for i in `seq 1 $nodecount`;
	do
		NUM=`expr $BASE_IP + $i`
		NODEIP="${SEGMENT}$NUM"
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODEIP $i "dbserver"
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
	rm -rf $DOCKER_VOLUME_PATH
	docker network rm $BRNAME
   
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

buildimage(){
	docker build -t $IMAGE --no-cache=true ./images/OEL7
}

dm_resize(){
	systemctl stop docker
	rm -rf /var/lib/docker
	mkdir -p /etc/systemd/system/docker.service.d
	cat > /etc/systemd/system/docker.service.d/storage.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --storage-opt dm.basesize=100G --storage-opt dm.loopdatasize=1024G --storage-opt dm.loopmetadatasize=4G --storage-opt dm.fs=xfs --storage-opt dm.blocksize=512K
EOF
	systemctl daemon-reload
	systemctl start docker
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
  "runonly" ) shift;runonly $*;;
  "runall" ) shift;runall $*;;
  "run" ) shift;run $*;;
  "startall" ) shift;startall $*;;
  "start" ) shift;start $*;;
  "delete" ) shift;delete $*;;
  "deleteall" ) shift;deleteall $*;;
  "stop" ) shift;stop $*;;
  "stopall" ) shift;stopall $*;;
  "buildimage") shift;buildimage $*;;
  "dm_resize") shift;dm_resize $*;;
  "heatrun") shift;heatrun $*;;
esac

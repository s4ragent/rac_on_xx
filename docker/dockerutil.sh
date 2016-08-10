#!/bin/bash

##common user specific value #######################
sudoer="opc"
sudokey="raconxx"
####################################################
#### docker user specific value  ###################
DOCKERSUBNET="10.153.0.0/16"
BRNAME="raconxx"
DeviceMapper_BaseSize="--storage-opt size=100G"
#DOCKER_VOLUME_PATH="/rac_on_docker"
####################################################
####common VIRT_TYPE specific value ################
VIRT_TYPE="docker"
DELETE_CMD="docker rm -f"
START_CMD="docker start"
STOP_CMD="docker stop"
INSTALL_OPS="-ignoreSysprereqs -ignorePrereq"
####################################################
####docker system  specific value ##################
IMAGE="s4ragent/rac_on_xx:OEL7"
#CAP_OPS="--cap-add=NET_ADMIN"
DOCKER_CAPS="--privileged=true --security-opt seccomp=unconfined"
#DOCKER_CAPS="--cap-add=ALL --security-opt=seccomp=unconfined"
DOCKER_START_OPS="--restart=always"
TMPFS_OPS="--shm-size=1200m"
####################################################

cd ..
source ./commonutil.sh

#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){
	NODENAME=$1
	IP=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	
	IsDeviceMapper=`docker info | grep devicemapper | grep -v grep | wc -l`

	if [ "$IsDeviceMapper" != "0" ]; then
     DeviceMapper_BaseSize=$DeviceMapper_BaseSize
	else
      DeviceMapper_BaseSize=""
	fi
   
    INSTANCE_ID=$(docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/media:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro $DeviceMapper_BaseSize $IMAGE /sbin/init)

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP

	docker exec $NODENAME useradd $sudoer                                                                                                          
	docker exec $NODENAME bash -c "echo \"$sudoer ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/opc"
	docker exec $NODENAME bash -c "mkdir /home/$sudoer/.ssh"
	docker cp ${sudokey}.pub $NODENAME:/home/$sudoer/.ssh/authorized_keys
	docker exec $NODENAME bash -c "chown -R ${sudoer} /home/$sudoer/.ssh && chmod 700 /home/$sudoer/.ssh && chmod 600 /home/$sudoer/.ssh/*"

	sleep 10
	docker exec $NODENAME systemctl start sshd
	docker exec $NODENAME systemctl enable sshd
	docker exec $NODENAME systemctl start NetworkManager
	docker exec $NODENAME systemctl enable NetworkManager
}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runall(){
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
	ansible-playbook --extra-vars "SERIAL=$SERIAL" -f 64 -T 30 -i $VIRT_TYPE rac.yml
}

deleteandrun(){
	deleteall && runall $1
}

deleteall(){
	common_stopall $*
   	common_deleteall $*
   
	#### VIRT_TYPE specific processing ###
	rm -rf ${sudokey}*
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
LOG="`date "+%Y%m%d-%H%M%S"`.log"
for i in `seq 1 $2`
do
    LOG="`date "+%Y%m%d-%H%M%S"`.log"
    deleteall >$LOG  2>&1
    runall $1 >$LOG  2>&1
done
}

case "$1" in
  "deleteandrun" ) shift;deleteandrun $*;;
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

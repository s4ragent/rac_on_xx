#!/bin/bash
source ../common.sh

####
#DOCKER_VOLUME_PATH="/rac_on_docker"


####
IMAGE="s4ragent/rac_on_xx:OEL7"
BRNAME="racbr"
#CAP_OPS="--cap-add=NET_ADMIN"
DOCKER_CAPS="--privileged=true --security-opt seccomp=unconfined"
#DOCKER_CAPS="--cap-add=ALL --security-opt=seccomp=unconfined"
DOCKER_START_OPS="--restart=always"
TMPFS_OPS="--shm-size=1200m"

dockerexec(){
	docker exec -ti $1 /bin/bash
}


createnetwork(){
    SEGMENT=`echo $NFS_SERVER | grep -Po '\d{1,3}\.\d{1,3}\.'`
    DOCKERSUBNET="${SEGMENT}0.0/16"
    docker network create -d bridge --subnet=$DOCKERSUBNET $BRNAME
}

#$1 node_number/nfs $2 ip $3 mount point
run(){

   if [ "$1" = "nfs" ]; then
    	NODENAME=nfs
   else
    	NODENAME=`getnodename $1`
   fi
   
   if [ "$DOCKER_VOLUME_PATH" != "" ]; then
    	mkdir -p $DOCKER_VOLUME_PATH/$NODENAME
	docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/media:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $DOCKER_VOLUME_PATH/$NODENAME:$3:rw $IMAGE /sbin/init
   else
    	docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/media:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro  $IMAGE /sbin/init
   fi   
   
   docker cp ../../rac_on_xx $NODENAME:/root/
}


deleteandrun(){
 deleteall && runall $1
}

runall(){
    HasNework=`docker network ls | grep racbr | wc -l`
    if [ "$HasNework" = "0" ]; then
        createnetwork
    fi

   run nfs $NFS_SERVER /nfs 	

   CNT=1
   for i in $NODE_LIST ;
   do
	run $CNT $i /u01
	CNT=`expr $CNT + 1`
   done
   
   docker exec -ti nfs bash /root/rac_on_xx/docker/nfsstartup.sh
   
   CNT=1
   for i in $NODE_LIST ;
   do
	NODENAME=`getnodename $CNT`
	#NODENAME=${DOMAIN_NAME}$CNT
	docker exec -ti $NODENAME bash /root/rac_on_xx/docker/nodestartup.sh
	CNT=`expr $CNT + 1`
   done
   
    if [ "$1" = "silent" ];  then
    	CNT=1
   	for i in $NODE_LIST ;
   	do
		NODENAME=`getnodename $CNT`
		docker exec -ti $NODENAME bash -c "cd /root/rac_on_xx && bash ./createsshkey.sh"
		CNT=`expr $CNT + 1`
	done
	NODENAME=`getnodename 1`
	docker exec -ti $NODENAME bash -c "cd /root/rac_on_xx && bash ./racutil.sh igd"
    fi
}

delete(){
	if [ "$1" = "nfs" ]; then
      		NODENAME=nfs
   	else
      		NODENAME=`getnodename $1`
   	fi
   	docker rm -f $NODENAME

   	if [ "$DOCKER_VOLUME_PATH" != "" ]; then
    		rm -rf $DOCKER_VOLUME_PATH/$NODENAME
    	fi
}

deleteall(){
   stopall
   CNT=1
   for i in $NODE_LIST ;
   do
	delete $CNT
	CNT=`expr $CNT + 1`
   done

   delete nfs
   docker network rm $BRNAME
}

stop(){ 
   if [ "$1" = "nfs" ]; then
      NODENAME=nfs
   else
      NODENAME=`getnodename $1`
   fi
   docker stop $NODENAME
}

stopall(){
   CNT=1
   for i in $NODE_LIST ;
   do
	stop $CNT
	CNT=`expr $CNT + 1`
   done
   stop nfs
}

start(){ 
   if [ "$1" = "nfs" ]; then
      NODENAME=nfs
   else
      NODENAME=`getnodename $1`
   fi
    docker start $NODENAME
}

startall(){
   start nfs
   CNT=1
   for i in $NODE_LIST ;
   do
	start $CNT
	CNT=`expr $CNT + 1`
   done
}


buildimage(){
    docker build -t $IMAGE --no-cache=true ./images/OEL7
}

getrootshlog(){
	docker exec -ti `getnodename $1` bash -c "cd /root/rac_on_xx && bash /root/rac_on_xx/racutil.sh getrootshlog $1"
}

case "$1" in
  "getrootshlog" ) shift;getrootshlog $*;;
  "deleteandrun" ) shift;deleteandrun $*;;
  "dockerexec" ) shift;dockerexec $*;;
  "createnetwork" ) shift;createnetwork $*;;
  "runall" ) shift;runall $*;;
  "run" ) shift;run $*;;
  "startall" ) shift;startall $*;;
  "start" ) shift;start $*;;
  "delete" ) shift;delete $*;;
  "deleteall" ) shift;deleteall $*;;
  "stop" ) shift;stop $*;;
  "stopall" ) shift;stopall $*;;
  "buildimage") shift;buildimage $*;;
  * ) echo "Ex " ;;
esac

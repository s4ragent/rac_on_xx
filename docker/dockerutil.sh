#!/bin/bash
source ../common.sh

IMAGE="s4ragent/rac_on_xx:OEL7"
BRNAME="racbr"
SHARE_VOLUME_PATH="/rac_on_docker"
#CAP_OPS="--cap-add=NET_ADMIN"
DOCKER_CAPS="--privileged=true --security-opt seccomp=unconfined"
#DOCKER_CAPS="--cap-add=ALL --security-opt=seccomp=unconfined"
DOCKER_START_OPS="--restart=always"
TMPFS_OPS="--shm-size=1200m"
MTU="9000"

##todo ubuntu 
#sudo apt-get install apparmor-utils
#sudo aa-complain /etc/apparmor.d/docker 

dockerexec(){
	docker exec -ti $1 /bin/bash
}


createnetwork(){
    SEGMENT=`echo $NFS_SERVER | grep -Po '\d{1,3}\.\d{1,3}\.'`
    DOCKERSUBNET="${SEGMENT}0.0/16"
    #docker network create -d --subnet=192.168.0.0/16
    docker network create -d bridge -o "com.docker.network.mtu"="$MTU" --subnet=$DOCKERSUBNET $BRNAME
}

run(){
    #docker run -c $CPU_SHARE -m $MEMORY_LIMIT $DOCKER_CAPS -d -h ${nodename}.${DOMAIN_NAME} --name ${nodename} --dns=127.0.0.1 -v /lib/modules:/lib/modules -v /docker/media:/media ractest:racbase$2 /sbin/init
    docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${1}.${DOMAIN_NAME} --name ${1} --net=$BRNAME --ip=$2 -v /sys/fs/cgroup:/sys/fs/cgroup:ro $3 $IMAGE /sbin/init
    docker cp ../../rac_on_xx $1:/root/
}

deleteandrun(){
 deleteall && runall $1
}

runall(){
    HasNework=`docker network ls | grep racbr | wc -l`
    if [ "$HasNework" = "0" ]; then
        createnetwork
    fi


   run nfs $NFS_SERVER "-v $SHARE_VOLUME_PATH$NFS_ROOT:$NFS_ROOT:rw" 	

   CNT=1
   for i in $NODE_LIST ;
   do
	NODENAME=`getnodename $CNT`
	#NODENAME=${DOMAIN_NAME}$CNT
	run $NODENAME $i "$TMPFS_OPS -v /media/:/media:ro"
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
	docker rm -f $1
}

deleteall(){
    #HasNework=`docker network ls | grep racbr | wc -l`
    #if [ "$HasNework" = "0" ]; then
    #    createnetwork
    #fi

   CNT=1
   for i in $NODE_LIST ;
   do
	NODENAME=`getnodename $CNT`
	delete $NODENAME
	CNT=`expr $CNT + 1`
   done
   docker exec -ti nfs bash -c "rm -rf $NFS_ROOT/*"
   delete nfs
   
   rm -rf $SHARE_VOLUME_PATH$NFS_ROOT/*
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
	docker exec -ti `getnodename $1` /root/rac_on_xx/racutil.sh getrootshlog $1
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

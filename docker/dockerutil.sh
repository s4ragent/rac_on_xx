#!/bin/bash
source ../common.sh

IMAGE="s4ragent/rac_on_xx:OEL7"
BRNAME="racbr"
#CAP_OPS="--cap-add=NET_ADMIN"
DOCKER_CAPS="--privileged=true"
DOCKER_START_OPS="--restart=always"
TMPFS_OPS="--tmpfs /run:rw,size=1200000k"

dockerexec(){
	docker exec -ti $1 /bin/bash
}


createnetwork(){
    SEGMENT=`echo $NFS_SERVER | grep -Po '\d{1,3}\.\d{1,3}\.'`
    DOCKERSUBNET="${SEGMENT}0.0/16"
    #docker network create -d --subnet=192.168.0.0/16
    docker network create -d bridge --subnet=$DOCKERSUBNET racbr
}

run(){
    #docker run -c $CPU_SHARE -m $MEMORY_LIMIT $DOCKER_CAPS -d -h ${nodename}.${DOMAIN_NAME} --name ${nodename} --dns=127.0.0.1 -v /lib/modules:/lib/modules -v /docker/media:/media ractest:racbase$2 /sbin/init
    docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${1}.${DOMAIN_NAME} --dns=127.0.0.1 --name ${1} --net=$BRNAME --ip=$2 -v /sys/fs/cgroup:/sys/fs/cgroup:ro $3 $IMAGE /sbin/init
    docker cp ../../rac_on_xx $1:/root/
    docker exec -ti $1 bash /root/rac_on_xx/docker/$4
}

runall(){
    HasNework=`docker network ls | grep racbr | wc -l`
    if [ "$HasNework" = "0" ]; then
        createnetwork
    fi

    run nfs $NFS_SERVER "-v /docker$NFS_ROOT:$NFS_ROOT:rw" nfsstartup.sh	

    startup="nodestartup.sh"
    if [ "$1" = "silent" ]; then
      startup="nodestartup_silent.sh"
   fi
   
   CNT=1
   for i in $NODE_LIST ;
   do
	NODENAME=`getnodename $CNT`
	#NODENAME=${DOMAIN_NAME}$CNT
	run $NODENAME $i "$TMPFS_OPS" $startup
	CNT=`expr $CNT + 1`
   done

   #CNT=1
   #for i in $NODE_LIST ;
   #do
#	NODENAME=`getnodename $CNT`
#	#NODENAME=${DOMAIN_NAME}$CNT
#	docker exec -d $NODENAME bash /root/rac_on_xx/docker/$4
#	CNT=`expr $CNT + 1`
#   done



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
   delete nfs
}


buildimage(){
    docker build -t $IMAGE --no-cache=true ./images/OEL7-init
}


case "$1" in
  "dockerexec" ) shift;dockerexec $*;;
  "createnetwork" ) shift;createnetwork $*;;
  "runall" ) shift;runall $*;;
  "run" ) shift;run $*;;
  "startall" ) shift;startall $*;;
  "delete" ) shift;delete $*;;
  "deleteall" ) shift;deleteall $*;;
  "stopall" ) shift;stopall $*;;
  "buildimage") shift;buildimage $*;;
  * ) echo "Ex " ;;
esac

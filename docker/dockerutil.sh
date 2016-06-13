#!/bin/bash
source ../common.sh

IMAGE="s4ragent/rac_on_xx:OEL7"
BRNAME="racbr"
#CAP_OPS="--cap-add=NET_ADMIN"
DOCKER_CAPS="--privileged=true"
TMPFS_OPS="--tmpfs size=1200000k"

createnetwork(){
    SEGMENT=`echo $NFS_SERVER | grep -Po '\d{1,3}\.\d{1,3}\.'`
    DOCKERSUBNET="${SEGMENT}0.0/16"
    #docker network create -d --subnet=192.168.0.0/16
    docker network create -d bridge --subnet=$DOCKERSUBNET racbr
}

run(){
    #docker run -c $CPU_SHARE -m $MEMORY_LIMIT $DOCKER_CAPS -d -h ${nodename}.${DOMAIN_NAME} --name ${nodename} --dns=127.0.0.1 -v /lib/modules:/lib/modules -v /docker/media:/media ractest:racbase$2 /sbin/init
    docker run $DOCKER_CAPS -d -h ${1}.${DOMAIN_NAME} --dns=127.0.0.1 --name ${1} --net=$BRNAME --ip=$2 -v /sys/fs/cgroup:/sys/fs/cgroup:ro $3 $IMAGE /sbin/init
}

runall(){
    HasNework=`docker network ls | grep racbr | wc -l`
    if [ "$HasNework" = "0" ]; then
        createnetwork
    fi
    
    
    run nfs $NFS_SERVER "-v /docker$NFS_ROOT:$NFS_ROOT:rw"	

}

buildimage(){
    docker build -t $IMAGE --no-cache=true ../images/OEL7-init
}


case "$1" in
  "createnetwork" ) shift;createnetwork $*;;
  "runall" ) shift;runall $*;;
  "run" ) shift;run $*;;
  "startall" ) shift;startall $*;;
  "deleteall" ) shift;deleteall $*;;
  "stopall" ) shift;stopall $*;;
  "buildimage") shift;buildimage $*;;
  * ) echo "Ex " ;;
esac

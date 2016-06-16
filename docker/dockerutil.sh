#!/bin/bash
source ../common.sh

IMAGE="s4ragent/rac_on_xx:OEL7"
BRNAME="racbr"
#CAP_OPS="--cap-add=NET_ADMIN"
#DOCKER_CAPS="--privileged=true"
DOCKER_CAPS="--cap-add=ALL --security-opt=seccomp=unconfined"
DOCKER_START_OPS="--restart=always"
TMPFS_OPS="--shm-size=1200m"
MTU="9000"

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
 deleteall && runall
}

runall(){
    HasNework=`docker network ls | grep racbr | wc -l`
    if [ "$HasNework" = "0" ]; then
        createnetwork
    fi

    rm -rf /docker$NFS_ROOT
    run nfs $NFS_SERVER "-v /docker$NFS_ROOT:$NFS_ROOT:rw" 	

    startup="nodestartup.sh"
    if [ "$1" = "silent" ]; then
      startup="nodestartup_silent.sh"
   fi
   
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
   
   CNT=1
   for i in $NODE_LIST ;
   do
	NODENAME=`getnodename $CNT`
	docker exec -ti $NODENAME bash -c "cd /root/rac_on_xx && bash ./createsshkey.sh"
	CNT=`expr $CNT + 1`
   done
   docker exec -ti node001 bash -c "cd /root/rac_on_xx && bash ./racutil.sh igd"
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
   docker network rm $BRNAME
}


buildimage(){
    docker build -t $IMAGE --no-cache=true ./images/OEL7
}


case "$1" in
  "deleteandrun" ) shift;deleteandrun $*;;
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

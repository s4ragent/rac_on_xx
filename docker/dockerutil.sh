#!/bin/bash
cd ..
source ../common.sh
DOCKERSUBNET="10.153.0.0/16"


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
sudoer="opc"
sudokey="opc"

dockerexec(){
	docker exec -ti $1 /bin/bash
}


createnetwork(){
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
   
   docker exec $NODENAME useradd $sudoer                                                                                                          
   docker exec $NODENAME bash -c "echo \"$sudoer ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/opc"
   docker exec $NODENAME bash -c "mkdir /home/$sudoer/.ssh"
   docker cp ${sudokey}.pub $NODENAME:/home/$sudoer/.ssh/authorized_keys
   docker exec $NODENAME bash -c "chown -R ${sudoer} /home/$sudoer/.ssh && chmod 700 /home/$sudoer/.ssh && chmod 600 /home/$sudoer/.ssh/*"

}


deleteandrun(){
 deleteall && runall $1
}

runall(){
    HasNework=`docker network ls | grep racbr | wc -l`
    if [ "$HasNework" = "0" ]; then
        createnetwork
    fi
    
    if [  ! -e $sudokey ] ; then
	ssh-keygen -t rsa -P "" -f $sudokey
	chmod 600 ${sudokey}*
    fi
   
   SEGMENT=`echo $DOCKERSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`

   NFSIP="${SEGMENT}$BASE_IP"
   run nfs $NFSIP /nfs 	
   
   NODE_LIST=""
   for i in `seq 1 $1`;
   do
        NUM=`expr $BASE_IP + $i`
    	NODEIP="${SEGMENT}$NUM"
	run $i $NODEIP /u01
	NODE_LIST="$NODE_LIST $NODEIP"
   done
   echo "NODELIST: $NODE_LIST" > nodelist.yml
   createansiblehost $1
   
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
    	
    	rm -rf ${sudokey}*
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

createansiblehost(){
	SEGMENT=`echo $DOCKERSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	NFSIP="${SEGMENT}$BASE_IP"
	mkdir -p docker/hosts
	cat > docker/hosts <<EOF
[localhost]
127.0.0.1

[nfs]
$NFSIP

EOF

	NUM=`expr $BASE_IP + 1`
	NODEIP="${SEGMENT}$NUM"
	cat >> docker/hosts <<EOF
[node1]
$NODEIP

[node_other]
EOF
	for i in `seq 2 $1`;
	do
		NUM=`expr 100 + $i`
		NODEIP="${SEGMENT}$NUM"
		echo $NODEIP >> docker/hosts
	done
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

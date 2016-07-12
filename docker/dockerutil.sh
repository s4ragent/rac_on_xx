#!/bin/bash
DOCKERSUBNET="10.153.0.0/16"
#DOCKER_VOLUME_PATH="/rac_on_docker"

cd ..
source ./common.sh

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
   
   updateansiblehost $1 $2
   
   if [ "$DOCKER_VOLUME_PATH" != "" ]; then
    	mkdir -p $DOCKER_VOLUME_PATH/$NODENAME
	docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/media:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $DOCKER_VOLUME_PATH/$NODENAME:$3:rw $IMAGE /sbin/init
   else
    	docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/media:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro  $IMAGE /sbin/init
   fi
   
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
   
   for i in `seq 1 $1`;
   do
        NUM=`expr $BASE_IP + $i`
    	NODEIP="${SEGMENT}$NUM"
	run $i $NODEIP /u01
   done
   export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no"
}

delete(){
	if [ "$1" = "nfs" ]; then
      		NODENAME=nfs
   	else
      		NODENAME=`getnodename $1`
      		SEGMENT=`echo $DOCKERSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
    		NUM=`expr $BASE_IP + $1`
    		NODEIP="${SEGMENT}$NUM"
    		rm -rf docker/host_vars/$NODEIP
   	fi
   	
   	docker rm -f $NODENAME

   	if [ "$DOCKER_VOLUME_PATH" != "" ]; then
    		rm -rf $DOCKER_VOLUME_PATH/$NODENAME
    	fi
    	
}

deleteall(){
   stopall
   NODE_LIST=`ls docker/host_vars`
   CNT=1
   for i in $NODE_LIST ;
   do
	delete $CNT
	CNT=`expr $CNT + 1`
   done

   delete nfs
   docker network rm $BRNAME
   rm -rf ${sudokey}*
   rm -rf docker/inventory
   rm -rf dodker/group_vars/all.yml
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
   NODE_LIST=`ls docker/host_vars`	
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
   NODE_LIST=`ls docker/host_vars`
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

updateansiblehost(){
   mkdir -p docker/host_vars
   if [ "$1" = "nfs" ]; then
   	SCAN0=`expr $BASE_IP - 20`
   	SCAN1=`expr $BASE_IP - 20 + 1`
   	SCAN2=`expr $BASE_IP - 20 + 2`
   	scan0_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN0"
   	scan1_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN1"
   	scan2_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN2"
   	
	cat > docker/inventory <<EOF
[nfs]
$2

[dbserver]
EOF
	cp vars.yml docker/group_vars/all.yml
	cat >> docker/group_vars/all.yml <<EOF
NFS_SERVER: $2
ansible_ssh_user: $sudoer
ansible_ssh_private_key_file: $sudokey
scan0_IP: $scan0_IP
scan1_IP: $scan1_IP
scan2_IP: $scan2_IP
EOF

   else
   	NODEIP=`expr $BASE_IP + $1`
   	VIPIP=`expr $NODEIP + 100`
   	NODENAME="$NODEPREFIX"`printf "%.3d" $1`
   	vxlan0_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
   	vxlan1_IP="`echo $vxlan1_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
   	vxlan2_IP="`echo $vxlan2_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
   	vip_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$VIPIP"
    	
    	echo $2 >> docker/inventory
    	cat > docker/host_vars/$2 <<EOF
NODENAME: ${NODENAME}
vxlan0_IP: $vxlan0_IP
vxlan1_IP: $vxlan1_IP
vxlan2_IP: $vxlan2_IP
public_IP: $vxlan0_IP
vip_IP: $vip_IP
EOF
   fi
   
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

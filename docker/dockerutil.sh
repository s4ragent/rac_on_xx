#!/bin/bash
DOCKERSUBNET="10.153.0.0/16"
#DOCKER_VOLUME_PATH="/rac_on_docker"
IMAGE="s4ragent/rac_on_xx:OEL7"
BRNAME="racbr"
#CAP_OPS="--cap-add=NET_ADMIN"
DOCKER_CAPS="--privileged=true --security-opt seccomp=unconfined"
#DOCKER_CAPS="--cap-add=ALL --security-opt=seccomp=unconfined"
DOCKER_START_OPS="--restart=always"
TMPFS_OPS="--shm-size=1200m"
export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no"

sudoer="opc"
sudokey="opc"
VIRT_TYPE="docker"

parse_yaml(){
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

cd ..
eval $(parse_yaml vars.yml)
NETWORKS=($NETWORK)

createnetwork(){
    docker network create -d bridge --subnet=$DOCKERSUBNET $BRNAME
}

#$1 node_number/nfs $2 ip $3 mount point
run(){
   if [ "$1" = "nfs" ]; then
    	NODENAME=nfs
   else
    	NODENAME="$NODEPREFIX"`printf "%.3d" $1`
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
   
}

deleteall(){
   ansible-playbook -i $VIRT_TYPE/inventory $VIRT_TYPE/deleteall.yml
   rm -rf ${sudokey}*
   rm -rf $VIRT_TYPE/inventory
   rm -rf $VIRT_TYPE/group_vars
   rm -rf $VIRT_TYPE/host_vars
   if [ "$DOCKER_VOLUME_PATH" != "" ]; then
    		rm -rf $DOCKER_VOLUME_PATH
   fi
}

stop(){ 
   if [ "$1" = "nfs" ]; then
      NODENAME=nfs
   else
      NODENAME="$NODEPREFIX"`printf "%.3d" $1`
   fi
   ansible-playbook -i $VIRT_TYPE/inventory $VIRT_TYPE/stopall.yml --limit $NODENAME
}

stopall(){
   ansible-playbook -i $VIRT_TYPE/inventory $VIRT_TYPE/stopall.yml
}

start(){ 
   if [ "$1" = "nfs" ]; then
      NODENAME=nfs
   else
      NODENAME="$NODEPREFIX"`printf "%.3d" $1`
   fi
   ansible-playbook -i $VIRT_TYPE/inventory $VIRT_TYPE/startall.yml --limit $NODENAME
}

startall(){
   ansible-playbook -i $VIRT_TYPE/inventory $VIRT_TYPE/startall.yml
}


buildimage(){
    docker build -t $IMAGE --no-cache=true ./images/OEL7
}


updateansiblehost(){
   mkdir -p $VIRT_TYPE/host_vars
   mkdir -p $VIRT_TYPE/group_vars
   if [ "$1" = "nfs" ]; then
   	SCAN0=`expr $BASE_IP - 20`
   	SCAN1=`expr $BASE_IP - 20 + 1`
   	SCAN2=`expr $BASE_IP - 20 + 2`
   	scan0_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN0"
   	scan1_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN1"
   	scan2_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN2"
   	
	cat > $VIRT_TYPE/inventory <<EOF
[nfs]
$1 ansible_ssh_host=$2
[dbserver]
EOF
   cat > $VIRT_TYPE/host_vars/$1 <<EOF
INSTANCE_ID: $1
EOF
	cp vars.yml $VIRT_TYPE/group_vars/all.yml
	cat >> $VIRT_TYPE/group_vars/all.yml <<EOF
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
    	
    	echo "$NODENAME ansible_ssh_host=$2" >> $VIRT_TYPE/inventory
    	cat > $VIRT_TYPE/host_vars/$NODENAME <<EOF
NODENAME: ${NODENAME}
vxlan0_IP: $vxlan0_IP
vxlan1_IP: $vxlan1_IP
vxlan2_IP: $vxlan2_IP
public_IP: $vxlan0_IP
vip_IP: $vip_IP
INSTANCE_ID: ${NODENAME}
EOF
   fi
   
}


case "$1" in
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

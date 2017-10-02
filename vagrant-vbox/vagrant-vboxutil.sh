#!/bin/bash

VIRT_TYPE="vagrant-vbox"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){

	NODENAME=$1
	IP=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID=$NODENAME
	
	IsDeviceMapper=`docker info | grep devicemapper | grep -v grep | wc -l`

#	if [ "$IsDeviceMapper" != "0" ]; then
		mkdir -p $DOCKER_VOLUME_PATH/$NODENAME
		StorageOps="-v $DOCKER_VOLUME_PATH/$NODENAME:/u01:rw"
#     		#DeviceMapper_BaseSize=$DeviceMapper_BaseSize
#	else
      		#DeviceMapper_BaseSize=""
#      		StorageOps=""
#	fi
#   
#    INSTANCE_ID=$(docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /media/:/media:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro $DeviceMapper_BaseSize $IMAGE /sbin/init)


    	INSTANCE_ID=$(docker run $DOCKER_START_OPS $DOCKER_CAPS -d -h ${NODENAME}.${DOMAIN_NAME} --name $NODENAME --net=$BRNAME --ip=$2 $TMPFS_OPS -v /boot/:/boot:ro -v /sys/fs/cgroup:/sys/fs/cgroup:ro $StorageOps $IMAGE /sbin/init)

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP

	docker exec ${NODENAME} useradd $ansible_ssh_user                                                                                                          
	docker exec ${NODENAME} bash -c "echo \"$ansible_ssh_user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/$ansible_ssh_user"
	docker exec ${NODENAME} bash -c "mkdir /home/$ansible_ssh_user/.ssh"
	docker cp ${ansible_ssh_private_key_file}.pub ${NODENAME}:/home/$ansible_ssh_user/.ssh/authorized_keys
	docker exec ${NODENAME} bash -c "chown -R ${ansible_ssh_user} /home/$ansible_ssh_user/.ssh && chmod 700 /home/$ansible_ssh_user/.ssh && chmod 600 /home/$ansible_ssh_user/.ssh/*"

	sleep 10
   
#   docker exec $NODENAME sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
	docker exec ${NODENAME} systemctl start sshd
	docker exec ${NODENAME} systemctl enable sshd
#	docker exec $NODENAME systemctl start NetworkManager
#	docker exec $NODENAME systemctl enable NetworkManager
}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	
	create_vagrantfile $nodecount $VIRT_TYPE
	

	
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
   	common_deleteall $*
	#### VIRT_TYPE specific processing ###
#	if [ -e "$ansible_ssh_private_key_file" ]; then
#   		rm -rf ${ansible_ssh_private_key_file}*
#	fi
  	
	rm -rf /tmp/$CVUQDISK
}

replaceinventory(){
	echo ""
}

get_External_IP(){
	get_Internal_IP $*	
}

get_Internal_IP(){
	if [ "$1" = "storage" ]; then
		NUM=`expr $BASE_IP`
	else
		NUM=`expr $BASE_IP + $1`
	fi
	SEGMENT=`echo $DOCKERSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	Internal_IP="${SEGMENT}$NUM"

	echo $Internal_IP	
}

create_vagrantfile()
{
	curdir=$2
	cd $curdir
	
	if [  ! -e $ansible_ssh_private_key_file ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi
	
	STORAGEIP=`get_Internal_IP storage`
	cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
	config.vm.box = "$BOX_URL"
	config.vm.define "storage" do |node|
 	node.vm.hostname = "storage"
	node.vm.network :forwarded_port, id: "ssh", guest: 22, host: $forward_sship
	node.vm.network "private_network", ip: "$STORAGEIP"
	node.vm.provider "virtualbox" do |vb|
		vb.memory = "$BOX_MEMORY"
	end

EOF

	
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_Internal_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
	cat >> Vagrantfile <<EOF
	config.vm.define "$NODENAME" do |node|
 	node.vm.hostname = "$NODENAME"
	node.vm.network :forwarded_port, id: "ssh", guest: 22, host: $forward_sship
	node.vm.network "private_network", ip: "$NODEIP"
	node.vm.provider "virtualbox" do |vb|
		vb.memory = "$BOX_MEMORY"
	end
	
EOF
	done

cat >> Vagrantfile <<EOF
end
EOF

}
case "$1" in
  "create_vagrantfile" ) shift;create_vagrantfile $*;;
esac

source ./common_menu.sh



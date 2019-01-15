#!/bin/bash

VIRT_TYPE="vagrant-vbox"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){
sleep 1s
}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	
	STORAGEIP=`get_External_IP storage`
	
	arg_string="storage,127.0.0.1:`common_get_ssh_port 0`,storage,0,storage"
	for i in `seq 1 $nodecount`;
	do
		#NODEIP=`get_External_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		arg_string="$arg_string $NODENAME,127.0.0.1:`common_get_ssh_port $i`,$NODENAME,$i,dbserver"
	done
	
	common_create_inventry "STORAGE_SERVER: $STORAGEIP" "$arg_string"
	
	create_box $nodecount
	
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	if [  ! -e $ansible_ssh_private_key_file ] ; then
		cp ~/.vagrant.d/insecure_private_key $ansible_ssh_private_key_file
		ssh-keygen -y -f $ansible_ssh_private_key_file > ${ansible_ssh_private_key_file}.pub
		chmod 600 ${ansible_ssh_private_key_file}*
	fi	
}

deleteall(){
 common_deleteall $*
	cd $VIRT_TYPE
	vagrant destroy -f
  	
	rm -rf /tmp/$CVUQDISK
}

replaceinventory(){
	echo ""
}

get_External_IP(){
	if [ "$1" = "storage" ]; then
		NUM=`expr $BASE_IP`
	else
		NUM=`expr $BASE_IP + $1`
	fi
	SEGMENT=`echo $VBOXSUBNET2 | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	External_IP="${SEGMENT}$NUM"
	echo $External_IP
}

get_Internal_IP(){
	if [ "$1" = "storage" ]; then
		NUM=`expr $BASE_IP`
	else
		NUM=`expr $BASE_IP + $1`
	fi
	SEGMENT=`echo $VBOXSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	Internal_IP="${SEGMENT}$NUM"

	echo $Internal_IP	
}

create_box()
{
	nodecount=$1

	cd $VIRT_TYPE
	#vagrant plugin install vagrant-persistent-storage
	vagrant plugin install vagrant-disksize

	cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
	config.vm.box = "$VBOX_URL"
	config.vm.provision "shell", path: "setup.sh"
	config.ssh.insert_key = false
EOF

#$1 nodename $2 disksize $3 memory $4 extenalip $5 internalip
	add_vagrantfile storage $VBOX_STORAGE_DISKSIZE $VBOX_STORAGE_MEMORY `get_External_IP storage` `get_Internal_IP storage` `common_get_ssh_port 0`

	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		
	add_vagrantfile $NODENAME $VBOX_STORAGE_DISKSIZE $VBOX_NODE_MEMORY `get_External_IP $i` 	`get_Internal_IP $i` `common_get_ssh_port $i`

	done

cat >> Vagrantfile <<EOF
end
EOF

cat > setup.sh <<EOF
#sudo yum -y install parted
sudo parted -s /dev/sda unit Gib mkpart primary $VBOX_ADD_DISKPART_SIZE 100% set $VBOX_ADD_DISKPART_NUM lvm on
sudo pvcreate /dev/sda${VBOX_ADD_DISKPART_NUM}
sudo vgextend $VBOX_VG_NAME /dev/sda${VBOX_ADD_DISKPART_NUM}
sudo lvextend -l +100%FREE /dev/mapper/${VBOX_LV_NAME}
sudo xfs_growfs /
EOF

if [ "$VBOX_TSO" = "off" ]; then
cat >> setup.sh <<EOF
ethtool -K eth0 tso off gro off gso off tx off rx off
ethtool -K eth1 tso off gro off gso off tx off rx off
chmod u+x /etc/rc.d/rc.local
echo "ethtool -K eth0 tso off gro off gso off tx off rx off" >> /etc/rc.d/rc.local
echo "ethtool -K eth1 tso off gro off gso off tx off rx off" >> /etc/rc.d/rc.local
EOF
fi
vagrant up

cd ..
}

#$1 nodename $2 disksize $3 memory $4 extenalip $5 intenalip $6 sshport
add_vagrantfile(){
	
	cat >> Vagrantfile <<EOF
	config.vm.define "$1" do |node|
 		node.vm.hostname = "$1"
		node.disksize.size = "$2"
		node.vm.network "forwarded_port", guest: 22, host: $6, id: "ssh"
		node.vm.network "private_network", ip: "$4", virtualbox__intnet: "storage"
#		node.vm.network "private_network", type: "dhcp"
#		node.vm.network "private_network", ip: "$5", virtualbox__intnet: "vxlan"
		node.vm.provider "virtualbox" do |vb|
			vb.memory = "$3"
			vb.cpus = 2
			vb.customize ['modifyvm', :id, '--nictype1', '$VBOX_NICTYPE']
			vb.customize ['modifyvm', :id, '--nictype2', '$VBOX_NICTYPE']
#			vb.customize ['modifyvm', :id, '--nictype3', '$VBOX_NICTYPE']
#			vb.customize ['modifyvm', :id, '--nictype4', '$VBOX_NICTYPE']			
			vb.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
			vb.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
#			vb.customize ['modifyvm', :id, '--nicpromisc3', 'allow-all']	
#			vb.customize ['modifyvm', :id, '--nicpromisc4', 'allow-all']			
		end
	end

EOF

}

source ./common_menu.sh



#!/bin/bash

VIRT_TYPE="kvm"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){

	NODENAME=$1
	IP=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID=${NODENAME}
	
	cp -R /var/lib/machines/rac_template /var/lib/machines/$INSTANCE_ID
	
	SEGMENT=`echo $NSPAWNSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	
	cat << EOF > /var/lib/machines/$INSTANCE_ID/etc/sysconfig/network-scripts/ifcfg-host0
DEVICE=host0
TYPE=Ethernet
IPADDR=$IP
GATEWAY=${SEGMENT}1
NETMASK=255.255.255.0
ONBOOT=yes
BOOTPROTO=static
NM_CONTROLLED=no
DELAY=0
EOF

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
                                                  
	systemd-machine-id-setup --root=/var/lib/machines/$INSTANCE_ID

	if [ -e /etc/redhat-release ]; then
		semanage fcontext -a -t svirt_sandbox_file_t "/var/lib/machines/$INSTANCE_ID(/.*)?"
		restorecon -R /var/lib/machines/$INSTANCE_ID
	fi
	
	machinectl start $INSTANCE_ID
	sleep 20s

}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	

	if [  ! -e $ansible_ssh_private_key_file ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi



	if [  ! -e /var/lib/libvirt/images/rac_template.img ] ; then
		buildimage
	fi

	STORAGEIP=`get_Internal_IP storage`
	run "storage" $STORAGEIP 0 "storage"
	
	common_update_all_yml "STORAGE_SERVER: $STORAGEIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_Internal_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODEIP $i "dbserver"
	done
	
	sleep 30s
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
   	common_deleteall $*
	#### VIRT_TYPE specific processing ###
	if [ -e "$ansible_ssh_private_key_file" ]; then
   		rm -rf ${ansible_ssh_private_key_file}*
	fi

  	
	rm -rf /tmp/$CVUQDISK
	virsh destroy rac_template
	virsh undefine rac_template
	rm -rf /var/lib/libvirt/images/rac_template.img
}

buildimage(){

#wget ${OS_URL}${OS_IMAGE} -O /var/lib/libvirt/images/${OS_IMAGE}

qemu-img create -f qcow2 /var/lib/libvirt/images/rac_template.img 100G

cat > /tmp/centos7.ks.cfg <<EOF 
#version=RHEL7

install
cdrom
text
cmdline
skipx

lang en_US.UTF-8
keyboard --vckeymap=jp106 --xlayouts=jp
timezone Asia/Tokyo --isUtc --nontp

network --activate --bootproto=dhcp --noipv6

zerombr
bootloader --location=mbr

clearpart --all --initlabel
part / --fstype=xfs --grow --size=1 --asprimary --label=root

rootpw --plaintext password
auth --enableshadow --passalgo=sha512
selinux --disabled
firewall --disabled
firstboot --disabled

reboot

%packages
%end
%post --log=/root/install-post.log

useradd $ansible_ssh_user                                                                                                          
echo "$ansible_ssh_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ansible_ssh_user
mkdir /home/$ansible_ssh_user/.ssh
echo "`cat ${ansible_ssh_private_key_file}.pub`"  > /home/$ansible_ssh_user/.ssh/authorized_keys
chown -R ${ansible_ssh_user} /home/$ansible_ssh_user/.ssh 
chmod 700 /home/$ansible_ssh_user/.ssh
chmod 600 /home/$ansible_ssh_user/.ssh/*

%end
EOF

virt-install \
  --name rac_template \
  --hvm \
  --virt-type kvm \
  --ram 1024 \
  --vcpus 1 \
  --arch x86_64 \
  --os-type linux \
  --os-variant rhel7 \
  --boot hd \
  --disk /var/lib/libvirt/images/rac_template.img \
  --network network=default \
  --graphics none \
  --serial pty \
  --console pty \
  --location ${OS_URL} \
  --initrd-inject /tmp/centos7.ks.cfg \
  --extra-args "inst.ks=file:/centos7.ks.cfg console=ttyS0"

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
	SEGMENT=`echo $NSPAWNSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	Internal_IP="${SEGMENT}$NUM"

	echo $Internal_IP	
}


source ./common_menu.sh




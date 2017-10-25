#!/bin/bash

VIRT_TYPE="kvm"

cd ..
source ./commonutil.sh

KVMSUBNET=`ip addr show $KVMBRNAME | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/[0-9]\+' | grep -o [0-9].*`

#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){

	NODENAME=$1
	IP=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID=${NODENAME}
	
	virt-clone --original rac_template --name $NODENAME --file /var/lib/libvirt/images/${NODENAME}.img
	
	SEGMENT=`echo $KVMSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	
	cat << EOF > /tmp/ifcfg-eth0
DEVICE=eth0
TYPE=Ethernet
IPADDR=$IP
GATEWAY=${SEGMENT}1
NETMASK=255.255.255.0
ONBOOT=yes
BOOTPROTO=static
NM_CONTROLLED=no
DELAY=0
EOF

virt-copy-in -d ${NODENAME} /tmp/ifcfg-eth0 /etc/sysconfig/network-scripts

virsh setvcpus ${NODENAME} ${CPUCOUNT} --config --maximum
virsh setvcpus ${NODENAME} ${CPUCOUNT} --config
virsh setmaxmem ${NODENAME} ${MEMSIZE} --config
virsh setmem ${NODENAME} ${MEMSIZE} --config

virsh start ${NODENAME}

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

	STORAGEIP=`get_External_IP storage`
	arg_string="storage,$STORAGEIP,storage,0,storage"
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_External_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		arg_string="$arg_string $NODENAME,$NODEIP,$NODENAME,$i,dbserver"
	done
	
	common_create_inventry "STORAGE_SERVER: $STORAGEIP" "$arg_string"

	run "storage" $STORAGEIP 0 "storage"
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_Internal_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODEIP $i "dbserver"
	done
	
	sleep 120s
#	CLIENTNUM=70
#	NUM=`expr $BASE_IP + $CLIENTNUM`
#	CLIENTIP="${SEGMENT}$NUM"	
#	run "client01" $CLIENTIP $CLIENTNUM "client"
	
}

deleteall(){
   	common_deleteall $*
	
	virsh destroy storage
	virsh undefine storage
	rm -rf /var/lib/libvirt/images/storage.img
	for i in `seq 1 100`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		virsh destroy $NODENAME
		virsh undefine $NODENAME
		rm -rf /var/lib/libvirt/images/${NODENAME}.img
	done


	if [ "$1" = "all" ]; then
   		rm -rf ${ansible_ssh_private_key_file}*
		virsh destroy rac_template
		virsh undefine rac_template
		rm -rf /var/lib/libvirt/images/rac_template.img
	fi

	#### VIRT_TYPE specific processing ###
	#if [ -e "$ansible_ssh_private_key_file" ]; then
   	#	rm -rf ${ansible_ssh_private_key_file}*
	#fi

	rm -rf /tmp/$CVUQDISK

}

buildimage(){

	if [ ! -e /var/lib/libvirt/images/${OS_IMAGE} ]; then
   		wget ${OS_URL}${OS_IMAGE} -O /var/lib/libvirt/images/${OS_IMAGE}
	fi

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

rootpw --plaintext $KVMPASS
auth --enableshadow --passalgo=sha512
selinux --disabled
firewall --disabled
firstboot --disabled

poweroff

%packages
%end
%post --log=/root/install-post.log

useradd $ansible_ssh_user
echo "$ansible_ssh_user:$KVMPASS" | chpasswd
echo "$ansible_ssh_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ansible_ssh_user
mkdir /home/$ansible_ssh_user/.ssh
echo "`cat ${ansible_ssh_private_key_file}.pub`"  > /home/$ansible_ssh_user/.ssh/authorized_keys
chown -R ${ansible_ssh_user} /home/$ansible_ssh_user/.ssh 
chmod 700 /home/$ansible_ssh_user/.ssh
chmod 600 /home/$ansible_ssh_user/.ssh/*

%end
EOF

#curl -O https://linux.oracle.com/switch/centos2ol.sh && sh centos2ol.sh
#yum -y distro-sync
#yum: name="kernel-uek-4*" state=latest enablerepo=ol7_UEKR4 disablerepo=ol7_UEKR3
#grub2-set-default {{ SWITCH_KERNEL }} && grub2-mkconfig -o /etc/grub2.cfg

#sed -i 's/HWADDR/#HWADDR/g' /etc/sysconfig/network-scripts/ifcfg-eth0
#sed -i 's/UUID/#UUID/g' /etc/sysconfig/network-scripts/ifcfg-eth0

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
  --noreboot \
  --serial pty \
  --console pty \
  --location /var/lib/libvirt/images/${OS_IMAGE} \
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
	SEGMENT=`echo $KVMSUBNET | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	Internal_IP="${SEGMENT}$NUM"

	echo $Internal_IP	
}


source ./common_menu.sh




#!/bin/bash
source ../common.sh

get_console(){
name=$1
gcloud compute instances get-serial-port-output $name
}

creategcedisk(){
	gcloud compute disks create "$1" --size $2 --type "pd-ssd"
}

creategceinstance(){
	name=$1
	ip=$2
	disksize=$3
	diskname="${1}-2"
	#creategcedisk  $diskname $disksize
	#gcloud compute instances create $name  --private-network-ip $ip --machine-type "n1-highmem-2" --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image centos-7 --boot-disk-type "pd-standard" --boot-disk-device-name $name --boot-disk-size 200GB  --disk "name=$diskname,device-name=$diskname,mode=rw,boot=no,auto-delete=yes" --metadata startup-script-url=https://raw.githubusercontent.com/s4ragent/rac_on_gce/master/gcestartup.sh
	gcloud compute instances create $name --private-network-ip $ip --machine-type "n1-highmem-2" --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image centos-7 --boot-disk-type "pd-ssd" --boot-disk-device-name $name --boot-disk-size 200GB  --metadata startup-script-url=https://raw.githubusercontent.com/s4ragent/rac_on_xx/master/gce/$4
}

create_centos(){
		name=$1
		gcloud compute instances create $name --machine-type $2 --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image centos-7 --boot-disk-type "pd-ssd" --boot-disk-device-name $name --boot-disk-size $3
}

create_ubuntu(){
		name=$1
		gcloud compute instances create $name --machine-type $2 --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image-family "/ubuntu-os-cloud/ubuntu-1604-lts" --boot-disk-type "pd-ssd" --boot-disk-device-name $name --boot-disk-size $3
}


startall(){
creategceinstance nfs $NFS_SERVER $ISCSI_DISKSIZE nfsstartup.sh	
CNT=1

startup="nodestartup.sh"
if [ "$1" = "silent" ]; then
  startup="nodestartup_silent.sh"
fi

for i in $NODE_LIST ;
do
	NODENAME=`getnodename $CNT`
	#NODENAME=${DOMAIN_NAME}$CNT
	creategceinstance $NODENAME $i $ISCSI_DISKSIZE $startup
	CNT=`expr $CNT + 1`
done
}

deleteall(){
#delete nfs
local INSTANCES="nfs"
CNT=1
for i in $NODE_LIST ;
do
	NODENAME=`getnodename $CNT`
	#NODENAME=${DOMAIN_NAME}$CNT
	INSTANCES="$INSTANCES $NODENAME"
	#delete $NODENAME
	CNT=`expr $CNT + 1`
done
delete "$INSTANCES"
}

deleteandstart(){
	deleteall && startall $1
}

ssh(){
name=$1
gcloud compute ssh $name --ssh-flag="-L 3389:127.0.0.1:3389" 
}

delete(){
name=$1
gcloud compute instances delete $name
}


case "$1" in
  "ssh" ) shift;ssh $*;;
  "create_centos" ) shift;create_centos $*;;
  "create_ubuntu" ) shift;create_ubuntu $*;;
  "deleteandstart" ) shift;deleteandstart $*;; 
  "get_console" ) shift;get_console $*;;  
  "deleteall" ) shift;deleteall $*;;
  "startall" ) shift;startall $*;;
  "delete" ) shift;delete $*;;
  "creategcedisk" ) shift;creategcedisk $*;;
  "creategceinstance" ) shift;creategceinstance $*;;
esac

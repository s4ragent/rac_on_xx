#!/bin/bash
cd ..
source ./common.sh

get_console(){
name=$1
gcloud compute instances get-serial-port-output $name
}

reset_password(){
	gcloud compute reset-windows-password $1
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

create_rhel6(){
		name=$1
		gcloud compute instances create $name --machine-type $2 --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image-family "/rhel-cloud/rhel-6" --boot-disk-type "pd-ssd" --boot-disk-device-name $name --boot-disk-size $3
}

create_2012(){
		name=$1
		gcloud compute instances create $name --machine-type $2 --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image-family "/windows-cloud/windows-2012-r2" --boot-disk-type "pd-ssd" --boot-disk-device-name $name --boot-disk-size $3
}

    

create_ubuntu(){
		name=$1
		gcloud compute instances create $name --machine-type $2 --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image-family "/ubuntu-os-cloud/ubuntu-1604-lts" --boot-disk-type "pd-ssd" --boot-disk-device-name $name --boot-disk-size $3
}

create_centos_docker(){
		name=$1
		gcloud compute instances create $name --machine-type $2 --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image centos-7 --boot-disk-type "pd-ssd" --boot-disk-device-name $name --boot-disk-size $3 --metadata startup-script-url=https://raw.githubusercontent.com/s4ragent/rac_on_xx/master/gce/enabledocker.sh
}

create_ubuntu_docker(){
		name=$1
		gcloud compute instances create $name --machine-type $2 --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image-family "/ubuntu-os-cloud/ubuntu-1604-lts" --boot-disk-type "pd-ssd" --boot-disk-device-name $name --boot-disk-size $3 --metadata startup-script-url=https://raw.githubusercontent.com/s4ragent/rac_on_xx/master/gce/enabledocker.sh
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
gcloud compute ssh $name --ssh-flag="-L 3389:127.0.0.1:3389" $2 $3 $4 $5 $6 $7 $8 $9
}

delete(){
name=$1
gcloud compute instances delete $name
}


case "$1" in
  "ssh" ) shift;ssh $*;;
  "reset_password" ) shift;reset_password $*;;
  "create_2012" ) shift;create_2012 $*;;
  "create_rhel6" ) shift;create_rhel6 $*;;
  "create_centos" ) shift;create_centos $*;;
  "create_ubuntu" ) shift;create_ubuntu $*;;
  "create_centos_docker" ) shift;create_centos_docker $*;;
  "create_ubuntu_docker" ) shift;create_ubuntu_docker $*;;
  "deleteandstart" ) shift;deleteandstart $*;; 
  "get_console" ) shift;get_console $*;;  
  "deleteall" ) shift;deleteall $*;;
  "startall" ) shift;startall $*;;
  "delete" ) shift;delete $*;;
  "creategcedisk" ) shift;creategcedisk $*;;
  "creategceinstance" ) shift;creategceinstance $*;;
esac

#!/bin/bash
source ./common.sh

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
	gcloud compute instances create $name --private-network-ip $ip --machine-type "n1-highmem-2" --network "default" --can-ip-forward --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/logging.write" --image centos-7 --boot-disk-type "pd-standard" --boot-disk-device-name $name --boot-disk-size 200GB  --metadata startup-script-url=https://raw.githubusercontent.com/s4ragent/rac_on_gce/master/$4
}

startallinstance(){
creategceinstance nfs $NFS_SERVER $ISCSI_DISKSIZE nfsstartup.sh	
CNT=1
for i in $NODE_LIST ;
do
	NODENAME=`getnodename $CNT`
	creategceinstance $NODENAME $i $ISCSI_DISKSIZE nodestartup.sh
	CNT=`expr $CNT + 1`
done
}

deleteall(){
CNT=1
for i in $NODE_LIST ;
do
	NODENAME=`getnodename $CNT`
	delete $NODENAME
	CNT=`expr $CNT + 1`
done
}

ssh(){
name=$1
gcloud compute ssh $name 
}

delete(){
name=$1
gcloud compute instances delete $name
}


case "$1" in
  "ssh" ) shift;ssh $*;;
  "get_console" ) shift;get_console $*;;  
  "deleteall" ) shift;deleteall $*;;
  "startallinstance" ) shift;startallinstance $*;;
  "delete" ) shift;delete $*;;
  "creategcedisk" ) shift;creategcedisk $*;;
  "creategceinstance" ) shift;creategceinstance $*;;
  * ) echo "Ex " ;;
esac

#!/bin/bash

VIRT_TYPE="k8s"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){

	NODENAME=$1
	IP=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID="${NODENAME}"
	
	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: $INSTANCE_ID
  namespace: $NAMESPACE
spec:
  hostname: $INSTANCE_ID
  subdomain: $DOMAIN_NAME
  containers:
    - name: $INSTANCE_ID
      image: s4ragent/rac_on_xx:OEL7
      ports:
        - containerPort: 80
          hostPort: 80
      securityContext:
        privileged: true
      volumeMounts:
        - name: cgroups
          mountPath: /sys/fs/cgroup
          readOnly: true
        - name: u01
          mountPath: /u01
          readOnly: false
  volumes:
    - hostPath:
        path: /sys/fs/cgroup
      name: cgroups
    - hostPath:
        path: /mnt/$INSTANCE_ID/u01
      name: u01
EOF

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP

cat >> $VIRT_TYPE/host_vars/$1 <<EOF
VXLAN_NODENAME: "${NODENAME}.$DOMAIN_NAME.$NAMESPACE.svc.$CLUSTERDOMAIN"
EOF

}

run_init(){
	NODENAME=$1
	
	kubectl --namespace $NAMESPACE exec ${NODENAME} useradd $ansible_ssh_user                                                                                                          
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- echo "$ansible_ssh_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ansible_ssh_user
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- mkdir /home/$ansible_ssh_user/.ssh
	kubectl cp ${ansible_ssh_private_key_file}.pub $NAMESPACE/{NODENAME}:/home/$ansible_ssh_user/.ssh/authorized_keys

	kubectl --namespace $NAMESPACEexec ${NODENAME} -- chown -R ${ansible_ssh_user} /home/$ansible_ssh_user/.ssh        
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- chmod 700 /home/$ansible_ssh_user/.ssh
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- chmod 600 /home/$ansible_ssh_user/.ssh/*

	kubectl cp ../rac_on_xx $NAMESPACE/${NODENAME}:/home/$ansible_ssh_user/

	kubectl exec --namespace $NAMESPACE ${NODENAME} -- chown -R ${ansible_ssh_user} /home/$ansible_ssh_user/rac_on_xx

	kubectl --namespace $NAMESPACE exec ${NODENAME} -- cp /home/$ansible_ssh_user/rac_on_xx/$VIRT_TYPE/retmpfs.sh /usr/local/bin/retmpfs.sh
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- chmod +x /usr/local/bin/retmpfs.sh
	
	kubectl --namespace $NAMESPACE exec ${NODENAME} cp /home/$ansible_ssh_user/rac_on_xx/$VIRT_TYPE/retmpfs.service /etc/systemd/system

	kubectl --namespace $NAMESPACE exec ${NODENAME} -- systemctl start retmpfs
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- systemctl enable retmpfs

	kubectl --namespace $NAMESPACE exec ${NODENAME} -- systemctl start sshd
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- systemctl enable sshd
}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	
	HasService=`kubectl --namespace $NAMESPACE get services | grep $DOMAIN_NAME | wc -l`
	if [ "$HasService" = "0" ]; then
	  kubectl create namespace $NAMESPACE
			cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: $DOMAIN_NAME
  namespace: $NAMESPACE
spec:
  selector:
    name: busybox
  clusterIP: None
EOF
	fi
	
	if [  ! -e $ansible_ssh_private_key_file ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
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

	sleep 60s
	run_init "storage"
	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run_init $NODENAME
	done


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
	
	kubectl --namespace $NAMESPACE delete service $DOMAIN_NAME
 kubectl delete namespace $NAMESPACE
	rm -rf /tmp/$CVUQDISK
}

buildimage(){
	docker build -t $IMAGE --no-cache=true ./images/OEL7
}
replaceinventory(){
	echo ""
}

get_External_IP(){
	get_Internal_IP $*	
}

get_Internal_IP(){
	if [ "$1" = "storage" ]; then
		echo "storage.$DOMAIN_NAME.$NAMESPACE.svc.$CLUSTERDOMAIN"
	else
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		echo "${NODENAME}.$DOMAIN_NAME.$NAMESPACE.svc.$CLUSTERDOMAIN"
	fi	
}


source ./common_menu.sh

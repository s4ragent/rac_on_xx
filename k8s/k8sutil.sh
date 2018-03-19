#!/bin/bash

VIRT_TYPE="k8s"

cd ..
source ./commonutil.sh


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run_pre(){

	NODENAME=$1
	INSTANCE_ID="${NODENAME}"


#create PersistentVolumeClaim u01
			cat <<EOF | kubectl create -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ${NODENAME}u01claim
  namespace: $NAMESPACE 
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: ${NAMESPACE}storageclass
EOF

sleep 30s

	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${INSTANCE_ID}
  namespace: $NAMESPACE
  labels:
    name: rac
spec:
  hostname: ${INSTANCE_ID}
  subdomain: $SUBDOMAIN
  containers:
    - name: ${INSTANCE_ID}
      image: s4ragent/rac_on_xx:OEL7
      command: ["/bin/sh"]
      args: ["-c", "while true; do sleep 10;done"]
      ports:
        - containerPort: 80
          hostPort: 80
      volumeMounts:
        - name: cgroups
          mountPath: /sys/fs/cgroup
          readOnly: true
        - name: u01
          mountPath: /u01
          readOnly: false
  volumes:
    - name: cgroups
      hostPath:
        path: /sys/fs/cgroup
    - name: u01
      persistentVolumeClaim:
        claimName: ${NODENAME}u01claim
EOF
}


#### VIRT_TYPE specific processing  (must define)###
#$1 nodename $2 ip $3 nodenumber $4 hostgroup#####
run(){

	NODENAME=$1
	IP=$2
	NODENUMBER=$3
	HOSTGROUP=$4
	INSTANCE_ID="${NODENAME}"


loopcnt=0
while :
do
	status=`kubectl --namespace $NAMESPACE get pods ${INSTANCE_ID} | grep Running | wc -l`
	if [ "$status" = "1" ]; then
		break
	fi	
	if [ "$loopcnt" = "40" ]; then
	 echo "pod creation failed"
		exit
	fi	
	loopcnt=`expr $loopcnt + 1`
	sleep 30s
done

	kubectl --namespace $NAMESPACE exec ${NODENAME} useradd $ansible_ssh_user                                                                                                          
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- bash -c "echo \"$ansible_ssh_user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/$ansible_ssh_user"


	kubectl cp ../rac_on_xx/$VIRT_TYPE/retmpfs.sh $NAMESPACE/${NODENAME}:/usr/local/bin/retmpfs.sh

#	kubectl cp ../rac_on_xx/$VIRT_TYPE/retmpfs.service $NAMESPACE/${NODENAME}:/etc/systemd/system/retmpfs.service
	
	kubectl cp ../rac_on_xx/$VIRT_TYPE/retmpfs.service $NAMESPACE/${NODENAME}:/usr/lib/systemd/system/retmpfs.service	

	kubectl --namespace $NAMESPACE exec ${INSTANCE_ID}  -- cp --remove-destination /usr/lib/systemd/system/retmpfs.service /etc/systemd/system/multi-user.target.wants/retmpfs.service

	kubectl --namespace $NAMESPACE exec ${NODENAME} -- chmod +x /usr/local/bin/retmpfs.sh
	
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- mkdir /home/$ansible_ssh_user/.ssh

	kubectl cp ../rac_on_xx/${ansible_ssh_private_key_file}.pub $NAMESPACE/${NODENAME}:/home/$ansible_ssh_user/${ansible_ssh_private_key_file}.pub

	kubectl --namespace $NAMESPACE exec ${NODENAME} -- mv /home/$ansible_ssh_user/${ansible_ssh_private_key_file}.pub /home/$ansible_ssh_user/.ssh/authorized_keys
	
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- chown -R ${ansible_ssh_user} /home/$ansible_ssh_user/.ssh
	        
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- chmod 700 /home/$ansible_ssh_user/.ssh
	
	kubectl --namespace $NAMESPACE exec ${NODENAME} -- chmod 600 /home/$ansible_ssh_user/.ssh/authorized_keys

#kubectl --namespace $NAMESPACE exec ${INSTANCE_ID}root  -- cp -d -R --preserve=all /bin /etc /home /lib /lib64 /opt /run /sbin /usr /var /u01

kubectl --namespace $NAMESPACE exec ${INSTANCE_ID}  -- cp -d -R --preserve=all /etc /home /usr /u01

kubectl --namespace $NAMESPACE exec ${INSTANCE_ID}  -- cp --remove-destination /u01/usr/lib/systemd/system/sshd.service /u01/etc/systemd/system/multi-user.target.wants/sshd.service

kubectl --namespace $NAMESPACE exec ${INSTANCE_ID}  -- chmod 755 /u01

	kubectl --namespace $NAMESPACE delete pod ${INSTANCE_ID}

sleep 60s

	cat <<EOF | kubectl create -f -
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: deployment${INSTANCE_ID}
  namespace: $NAMESPACE
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: $INSTANCE_ID
    spec:
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
        - name: modules
          mountPath: /lib/modules
          readOnly: true
        - name: dev
          mountPath: /dev
          readOnly: false          
        - name: u01
          mountPath: /u01
          subPath: u01
          readOnly: false
        - name: u01
          mountPath: /etc
          subPath: etc
          readOnly: false
        - name: u01
          mountPath: /home
          subPath: home
          readOnly: false
        - name: u01
          mountPath: /usr
          subPath: usr
          readOnly: false
      volumes:
      - name: cgroups
        hostPath:
          path: /sys/fs/cgroup
      - name: dev
        hostPath:
          path: /dev
      - name: modules
        hostPath:
          path: /lib/modules
      - name: u01
        persistentVolumeClaim:
          claimName: ${NODENAME}u01claim
---
apiVersion: v1
kind: Service
metadata:
  name: ${INSTANCE_ID}
  namespace: $NAMESPACE
spec:
  selector:
    app: $INSTANCE_ID
  clusterIP: None
  ports:
  - name: foo
    port: 80
    targetPort: 80        
EOF

	#$NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP
	common_update_ansible_inventory $NODENAME $IP $INSTANCE_ID $NODENUMBER $HOSTGROUP

cat >> $VIRT_TYPE/host_vars/$1 <<EOF
VXLAN_NODENAME: "${INSTANCE_ID}.$NAMESPACE.svc.$CLUSTERDOMAIN"
EOF

}

run_after(){
	NODENAME=$1
 loopcnt=0
	while :
	do
		status=`kubectl --namespace $NAMESPACE get pods $NODENAME | grep Running | wc -l`
		if [ "$status" = "1" ]; then
			break
		fi	
		if [ "$loopcnt" = "30" ]; then
			break
		fi	
		loopcnt=`expr $loopcnt + 1`
		sleep 30s
	done
	
	
#	kubectl --namespace $NAMESPACE exec ${NODENAME} -- systemctl start retmpfs
#	kubectl --namespace $NAMESPACE exec ${NODENAME} -- systemctl enable retmpfs

#	kubectl --namespace $NAMESPACE exec ${NODENAME} --  sed -i "s/^#Port 22/Port $SSHPORT/" /etc/ssh/sshd_config

#	kubectl --namespace $NAMESPACE exec ${NODENAME} -- systemctl start sshd
#	kubectl --namespace $NAMESPACE exec ${NODENAME} -- systemctl enable sshd
}

#### VIRT_TYPE specific processing  (must define)###
#$1 nodecount                                  #####
runonly(){
	if [ "$1" = "" ]; then
		nodecount=3
	else
		nodecount=$1
	fi
	
	HasService=`kubectl --namespace $NAMESPACE get services | grep $SUBDOMAIN | wc -l`
	if [ "$HasService" = "0" ]; then

#create namespace
	  kubectl create namespace $NAMESPACE


#create StorageClass
			cat <<EOF | kubectl create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: ${NAMESPACE}storageclass
  namespace: $NAMESPACE
provisioner: $PROVISIONER
parameters:
  $PARAMETER_1
  $PARAMETER_2
  $PARAMETER_3
EOF

	fi
	
	if [  ! -e $ansible_ssh_private_key_file ] ; then
		ssh-keygen -t rsa -P "" -f $ansible_ssh_private_key_file
		chmod 600 ${ansible_ssh_private_key_file}*
	fi


	run_pre "storage"
	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run_pre $NODENAME
	done

	STORAGEIP=`get_Internal_IP storage`
	run "storage" $STORAGEIP 0 "storage"
	
	common_update_all_yml "STORAGE_SERVER: $STORAGEIP"
	
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_Internal_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run $NODENAME $NODEIP $i "dbserver"
	done

	run_after "storage"
	for i in `seq 1 $nodecount`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		run_after $NODENAME
	done


	cat <<EOI | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: ansible
  namespace: $NAMESPACE
  labels:
    name: rac
spec:
  hostname: ansible
  containers:
    - name: ansible
      image: s4ragent/rac_on_xx:OEL7
      command: ["/bin/sh"]
      args: ["-c", "while true; do sleep 10;done"]

EOI

sleep 30s                                                                                                     
#	kubectl cp /media/$DB_MEDIA1 $NAMESPACE/${NODE1}:$MEDIA_PATH/$DB_MEDIA1

#	kubectl cp /media/$GRID_MEDIA1 $NAMESPACE/${NODE1}:$MEDIA_PATH/$GRID_MEDIA1
	

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

		kubectl --namespace $NAMESPACE delete pod storage
		kubectl --namespace $NAMESPACE delete pvc storageu01claim
		
	for i in `seq 1 10`;
	do
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
		kubectl --namespace $NAMESPACE delete pod $NODENAME
		kubectl --namespace $NAMESPACE delete pvc ${NODENAME}u01claim
	done
	
	kubectl --namespace $NAMESPACE delete service $SUBDOMAIN
 kubectl delete namespace $NAMESPACE
 	kubectl --namespace $NAMESPACE delete storageclass ${NAMESPACE}storageclass 
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
		echo "storage.$NAMESPACE.svc.$CLUSTERDOMAIN"
	else
		NODENAME="$NODEPREFIX"`printf "%.3d" $1`
		echo "${NODENAME}.$NAMESPACE.svc.$CLUSTERDOMAIN"
	fi	
}

copymedia(){
	#NODE1="$NODEPREFIX"`printf "%.3d" 1`                                                                                  
	kubectl cp ../rac_on_xx $NAMESPACE/ansible:/root/

	kubectl cp /media/$DB_MEDIA1 $NAMESPACE/ansible:/media/$DB_MEDIA1

	kubectl cp /media/$GRID_MEDIA1 $NAMESPACE/ansible:/media/$GRID_MEDIA1
	
}

install(){
common_execansible centos2oel.yml
common_execansible rac.yml --tags security,vxlan_conf,dnsmasq,setresolvconf
common_execansible rac.yml --skip-tags security,dnsmasq,vxlan_conf
# 	NODE1="$NODEPREFIX"`printf "%.3d" 1`
#	kubectl --namespace $NAMESPACE exec ${NODE1} 'cd /root/rac_on_xx/k8s && bash k8sutil.sh after_runonly'
}

runall_k8s(){
	runonly $*
	copymedia
	kubectl exec --namespace raconxx -ti ansible -- /bin/bash -c "cd /root/rac_on_xx/k8s;nohup bash k8sutil.sh install"
}

case "$1" in
  "runpod" ) shift;runonly $*;;
  "install" ) shift;install $*;;
  "runall_k8s" ) shift;runall_k8s $*;;
  "copymedia" ) shift;copymedia $*;;
esac

source ./common_menu.sh

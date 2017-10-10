#!/bin/bash
export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30"
export  ANSIBLE_INVENTORY_IGNORE="~, .orig, .bak, .ini, .cfg, .retry, .pyc, .pyo, .yml, .md, .sh, images, .log, .service,Vagrantfile"
export ANSIBLE_LOG_PATH="./ansible-`date +%Y%m%d%H%M%S`.log"


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

eval $(parse_yaml common_vars.yml)
eval $(parse_yaml $VIRT_TYPE/vars.yml)

common_execansible(){
			starttime=`date`
   ansible-playbook -f 64 -T 600 -i $VIRT_TYPE $*
   echo "###START $starttime END `date` ###"
}

common_runall(){
	runonly $*
	common_execansible centos2oel.yml
 	sleep 180s
	common_execansible rac.yml
}

common_preinstall(){
	runonly $*
	common_execansible centos2oel.yml
	sleep 180s
	common_execansible rac.yml --skip-tags installdbca
}

common_after_runonly(){
	common_execansible centos2oel.yml
	sleep 180s
	common_execansible rac.yml
}

common_install_dbca(){
	common_execansible rac.yml --tags installdbca
}


common_heatrun(){
for i in `seq 1 $2`
do
    LOG="`date "+%Y%m%d-%H%M%S"`_$VIRT_TYPE.log"
    deleteall >$LOG  2>&1
    STARTTIME=`date "+%Y%m%d-%H%M%S"`
    common_runall $1 >>$LOG  2>&1
    echo "START $STARTTIME" >>$LOG
    echo "END `date "+%Y%m%d-%H%M%S"`" >>$LOG
done
}

common_heatrun_full(){
for i in `seq 1 $2`
do
    LOG="`date "+%Y%m%d-%H%M%S"`_$VIRT_TYPE.log"
    deleteall >$LOG  2>&1
    STARTTIME=`date "+%Y%m%d-%H%M%S"`
    common_runall $1 >>$LOG  2>&1
    echo '#########STOP NODE 1################'
    common_stop 1 >>$LOG  2>&1
    common_execansible rac.yml --tags crsctl --limit "$NODEPREFIX"`printf "%.3d" 2` >>$LOG  2>&1
    echo '#########START NODE 1################'
    common_start 1 >>$LOG  2>&1
    sleep 480s
    common_execansible rac.yml --tags crsctl --limit "$NODEPREFIX"`printf "%.3d" 2` >>$LOG  2>&1
    echo '#########STOP ALL################'
    common_stopall >>$LOG  2>&1
    echo '#########START STORAGE################'
    common_start storage >>$LOG  2>&1
    echo '#########STOP STORAGE################'
    common_stop storage >>$LOG  2>&1
    echo '#########START ALL################'
    common_startall >>$LOG  2>&1
    sleep 480s
    common_execansible rac.yml --tags crsctl --limit "$NODEPREFIX"`printf "%.3d" 2` >>$LOG  2>&1
    echo "START $STARTTIME" >>$LOG
    echo "END `date "+%Y%m%d-%H%M%S"`" >>$LOG
done
}


common_deleteall(){
   common_execansible stop.yml
   common_execansible delete.yml
   
   rm -rf $VIRT_TYPE/*.inventory
   rm -rf $VIRT_TYPE/group_vars
   rm -rf $VIRT_TYPE/host_vars
   
}

common_stop(){ 
   if [ "$1" = "storage" ]; then
      NODENAME=storage
   else
      NODENAME="$NODEPREFIX"`printf "%.3d" $1`
   fi
   common_execansible stop.yml --limit $NODENAME
}

common_stopall(){
   common_execansible stop.yml
}

common_start(){ 
   if [ "$1" = "storage" ]; then
      NODENAME=storage
   else
      NODENAME="$NODEPREFIX"`printf "%.3d" $1`
   fi
   common_execansible start.yml --limit $NODENAME
   replaceinventory
}

common_startall(){
   common_execansible start.yml
   replaceinventory
}

#$NODENAME $IP $INSTANCE_ID $nodenumber $hostgroup
common_update_ansible_inventory(){
hostgroup=$5
if [ ! -e $VIRT_TYPE/${hostgroup}.inventory ]; then
  mkdir -p $VIRT_TYPE/host_vars
  cat > $VIRT_TYPE/${hostgroup}.inventory <<EOF
[$hostgroup]
EOF
fi

NODEIP=`expr $BASE_IP + $4`
VIPIP=`expr $NODEIP + 100`
vxlan0_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
vxlan1_IP="`echo $vxlan1_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
vxlan2_IP="`echo $vxlan2_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
vip_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$VIPIP"
    	
echo "$1 ansible_ssh_host=$2" >> $VIRT_TYPE/${hostgroup}.inventory
cat > $VIRT_TYPE/host_vars/$1 <<EOF
NODENAME: $1
vxlan0_IP: $vxlan0_IP
vxlan1_IP: $vxlan1_IP
vxlan2_IP: $vxlan2_IP
public_IP: $vxlan0_IP
vip_IP: $vip_IP
INSTANCE_ID: $3
EOF
}

#$1 addtional all.yml var
common_update_all_yml(){
SCAN0=`expr $BASE_IP - 20`
SCAN1=`expr $BASE_IP - 20 + 1`
SCAN2=`expr $BASE_IP - 20 + 2`
scan0_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN0"
scan1_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN1"
scan2_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN2"	
	
if [ ! -e $VIRT_TYPE/group_vars/all.yml ]; then
	mkdir -p $VIRT_TYPE/group_vars
	cp common_vars.yml $VIRT_TYPE/group_vars/all.yml
	cat $VIRT_TYPE/vars.yml >> $VIRT_TYPE/group_vars/all.yml
	
		cat >> $VIRT_TYPE/group_vars/all.yml <<EOF
scan0_IP: $scan0_IP
scan1_IP: $scan1_IP
scan2_IP: $scan2_IP
EOF
	
fi

if [ "$1" != "" ]; then
	echo "$1" >> $VIRT_TYPE/group_vars/all.yml
fi

}


#$1 instance_name $2 external_IP
common_replaceinventory(){
	sed -i -e "s/$1 ansible_ssh_host=.*\$/$1 ansible_ssh_host=${2}/g" $VIRT_TYPE/*.inventory
}

common_ssh(){
	

if [ "$2" != "" ]; then
	if [ "$3" != "" ]; then
		if [ "$4" != "" ]; then
			ssh -o StrictHostKeyChecking=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -g -L $2:$3:$4 -i $ansible_ssh_private_key_file $ansible_ssh_user@`get_External_IP $1` 
		else
			ssh -o StrictHostKeyChecking=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -g -L $2:127.0.0.1:$3 -i $ansible_ssh_private_key_file $ansible_ssh_user@`get_External_IP $1`	
		fi
	else
		ssh -o StrictHostKeyChecking=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -g -L $2:127.0.0.1:$2 -i $ansible_ssh_private_key_file $ansible_ssh_user@`get_External_IP $1`
	fi
else
	ssh -o StrictHostKeyChecking=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -g -L $FOWARD_PORT:127.0.0.1:8080 -i $ansible_ssh_private_key_file $ansible_ssh_user@`get_External_IP $1`
fi

}

common_create_box()
{
	nodecount=$1

	cd $VIRT_TYPE
	vagrant plugin install vagrant-disksize
	vagrant box add $VBOX_NAME $VBOX_URL

	cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
	config.vm.box = "$VBOX_NAME"
	config.vm.provision "shell", path: "setup.sh"
	config.ssh.insert_key = false
EOF

	STORAGEIP=`get_External_IP storage`
	cat >> Vagrantfile <<EOF
	config.vm.define "storage" do |node|
 		node.vm.hostname = "storage"
 		node.disksize.size = '100GB'
		node.vm.network "private_network", ip: "$STORAGEIP"
		node.vm.provider "virtualbox" do |vb|
			vb.memory = "$VBOX_STORAGE_MEMORY"
		end
	end

EOF

	
	for i in `seq 1 $nodecount`;
	do
		NODEIP=`get_External_IP $i`
		NODENAME="$NODEPREFIX"`printf "%.3d" $i`
	cat >> Vagrantfile <<EOF
	config.vm.define "$NODENAME" do |node|
 		node.vm.hostname = "$NODENAME"
		node.vm.network "private_network", ip: "$NODEIP"
		node.disksize.size = '100GB'
		node.vm.provider "virtualbox" do |vb|
			vb.memory = "$VBOX_NODE_MEMORY"
		end
	end
	
EOF
	done

cat >> Vagrantfile <<EOF
end
EOF
vagrant up

cd ..
}

#$1 ""
#$2 "$NODENAME,$IP,$INSTANCE_ID,$NODENUMBER,$HOSTGROUP $NODENAME,$IP,$INSTANCE_ID,$NODENUMBER,$HOSTGROUP"
common_create_inventry(){
	common_update_all_yml "$1"
	nodelist=$2
	for node in $nodelist;
	do
		cargs=`echo $node | sed 's/,/ /g'`
		common_update_ansible_inventory $cargs
	done
}

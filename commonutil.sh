#!/bin/bash
export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no"

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

eval $(parse_yaml vars.yml)

common_deleteall(){
   ansible-playbook -i $VIRT_TYPE/inventory deleteall.yml
   
   rm -rf $VIRT_TYPE/inventory
   rm -rf $VIRT_TYPE/group_vars
   rm -rf $VIRT_TYPE/host_vars
   
}

common_stop(){ 
   if [ "$1" = "nfs" ]; then
      NODENAME=nfs
   else
      NODENAME="$NODEPREFIX"`printf "%.3d" $1`
   fi
   ansible-playbook -i $VIRT_TYPE/inventory stopall.yml --limit $NODENAME
}

common_stopall(){
   ansible-playbook -i $VIRT_TYPE/inventory stopall.yml
}

common_start(){ 
   if [ "$1" = "nfs" ]; then
      NODENAME=nfs
   else
      NODENAME="$NODEPREFIX"`printf "%.3d" $1`
   fi
   ansible-playbook -i $VIRT_TYPE/inventory startall.yml --limit $NODENAME
}

common_startall(){
   ansible-playbook -i $VIRT_TYPE/inventory startall.yml
}

#$NODENAME $IP $INSTANCE_ID $nodenumber $runInstaller ops(-ignoreSysprereqs -ignorePrereq)
common_updateansiblehost(){
   mkdir -p $VIRT_TYPE/host_vars
   mkdir -p $VIRT_TYPE/group_vars
   if [ "$1" = "nfs" ]; then
   	SCAN0=`expr $BASE_IP - 20`
   	SCAN1=`expr $BASE_IP - 20 + 1`
   	SCAN2=`expr $BASE_IP - 20 + 2`
   	scan0_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN0"
   	scan1_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN1"
   	scan2_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$SCAN2"
   	
	cat > $VIRT_TYPE/inventory <<EOF
[nfs]
$1 ansible_ssh_host=$2
[dbserver]
EOF
   cat > $VIRT_TYPE/host_vars/$1 <<EOF
INSTANCE_ID: $3
EOF
	cp vars.yml $VIRT_TYPE/group_vars/all.yml
	cat >> $VIRT_TYPE/group_vars/all.yml <<EOF
NFS_SERVER: $2
ansible_ssh_user: $sudoer
ansible_ssh_private_key_file: $sudokey
scan0_IP: $scan0_IP
scan1_IP: $scan1_IP
scan2_IP: $scan2_IP
installops: $5
DELETE_CMD: $DELETE_CMD
START_CMD: $START_CMD
STOP_CMD: $STOP_CMD
EOF

   else
   	NODEIP=`expr $BASE_IP + $4`
   	VIPIP=`expr $NODEIP + 100`
   	vxlan0_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
   	vxlan1_IP="`echo $vxlan1_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
   	vxlan2_IP="`echo $vxlan2_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$NODEIP"
   	vip_IP="`echo $vxlan0_NETWORK | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`$VIPIP"
    	
    	echo "$1 ansible_ssh_host=$2" >> $VIRT_TYPE/inventory
    	cat > $VIRT_TYPE/host_vars/$1 <<EOF
NODENAME: $1
vxlan0_IP: $vxlan0_IP
vxlan1_IP: $vxlan1_IP
vxlan2_IP: $vxlan2_IP
public_IP: $vxlan0_IP
vip_IP: $vip_IP
INSTANCE_ID: $3
EOF
   fi
   
}

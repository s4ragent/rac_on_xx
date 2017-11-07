rac_on_xx/kvm
====

 Oracle RAC on KVM

## Description
- basic infomation

|||
|-----|-----|
|OS|Oracle Linux 7.x|
|Storage|NFS4 with Flex ASM|
|L2 Network emulation|vxlan|
|DNS|dnsmasq on each container|

- Network infomation (e.g. 3-nodes RAC)

|hostname/container name/vip|eth0|vxlan0(public)|vxlan1(internal)|vxlan2(asm)|
|--------|--------|-------|-------|-------|
|storage|192.168.122.50|-|-|-|
|node001|192.168.122.51|192.168.0.51|192.168.100.51|192.168.200.51|
|node002|192.168.122.52|192.168.0.52|192.168.100.52|192.168.200.52|
|node003|192.168.122.53|192.168.0.53|192.168.100.53|192.168.200.53|
|node001.vip|-|192.168.0.151|-|-|
|node002.vip|-|192.168.0.152|-|-|
|node003.vip|-|192.168.0.152|-|-|
|scan1.vip|-|192.168.0.31|-|-|
|scan2.vip|-|192.168.0.32|-|-|
|scan3.vip|-|192.168.0.33|-|-|


- Storage infomation 

|Diskgroup name|use|asm device path|redundancy|size(MB)|size(MB)(e.g. 3-nodes RAC)|
|--------|--------|-------|-------|-------|-------|
|VOTE|ocr and voting disk|/u01/oradata/vote.img|external| 40960 + ( num_of_nodes * 2048 )|47104|
|DATA|Database files|/u01/oradata/data.img|external| 5120 + ( num_of_nodes * 1024 ) |8192|
|FRA|flash recovery area|/u01/oradata/fra.img|external|25600|25600|


## Requirement
- ubuntu/debian(Kernel 3.18 or later), CentOS/RHEL/OEL 7.2 or later
- docker 1.12 or later
- ansible 2.2.1 or later
- Oracle 12c Release 2 (12.2) Clusterware and Database software 
- 1core CPU per VM and  5GB Memory per VM


## Setup
### 1. create swap (unless your server has 4GB or more of memory )
    #dd if=/dev/zero of=/swapfile bs=4096 count=1M
    #mkswap /swapfile
    #echo "/swapfile none swap sw 0 0" >> /etc/fstab
    #swapon -a
### 2. install prerequisite packages
    ##CentOS 7.3
    #yum -y install git screen qemu-img epel-release
    #yum -y install python-pip openssl-devel gcc python-devel git unzip --enablerepo=epel 
    #yum -y install libguestfs-tools libvirt libvirt-client python-virtinst qemu-kvm virt-manager virt-top virt-viewer virt-who virt-install bridge-utils 
    #systemctl start libvirtd
    #systemctl enable libvirtd
    
    ##ubuntu 16.04 
    #apt-get update
    #apt-get install -y git screen qemu-utils python-dev python-pip libssl-dev unzip
    #apt-get install -y kvm libguestfs-tools virt-manager libvirt-bin bridge-utils
    #systemctl start libvirt-bin
    #systemctl enable libvirt-bin
### 3. install ansible
    #pip install pip --upgrade
    #pip install ansible    

### 4. download Oracle 12c Release 2 (12.2) Clusterware and Database software and locate them on /media
    # ls -al  /media
    total 6297260
    -rw-r--r-- 1 root root 3453696911 Mar 28 12:30 linuxx64_12201_database.zip
    -rw-r--r-- 1 root root 2994687209 Mar 28 12:31 linuxx64_12201_grid_home.zip
### 5. cloning an Repository
    #git clone https://github.com/s4ragent/rac_on_xx

## Usage
execute kvmutil.sh   (kvmutil.sh execute ansible-playbook and build RAC cluster. no option create 3-nodes RAC)

    ##create 3-nodes RAC#
    #cd rac_on_xx/kvm
    #bash kvmutil.sh runall

if you want to build 5-nodes RAC

    ##create 5-nodes RAC#
    #cd rac_on_xx/kvm
    #bash kvmutil.sh runall 5

if you want to log in node001

    #kvmutil.sh ssh 1

if you want to stop first vm

    #bash kvmutil.sh stop 1

if you want to stop storage vm

    #bash kvmutil.sh stop storage

and restart first container

    #bash kvmutil.sh start 1
    
if you want to start all containers

    #bash kvmutil.sh startall

if you want to delete all vm

    #bash kvmutil.sh deleteall

## Licence
[MIT]

## Author
@s4r_agent

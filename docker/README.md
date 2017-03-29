rac_on_xx/docker
====

 Oracle RAC on docker

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
|storage|10.153.0.50|-|-|-|
|node001|10.153.0.51|192.168.0.51|192.168.100.51|192.168.200.51|
|node002|10.153.0.52|192.168.0.52|192.168.100.52|192.168.200.52|
|node003|10.153.0.53|192.168.0.53|192.168.100.53|192.168.200.53|
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

## Demo (12-nodes RAC on ubuntu docker)
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/docker/docker01.png)
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/docker/docker02.png)
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/docker/docker03.png)
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/docker/docker04.png)

## Requirement
- ubuntu/debian(Kernel 3.18 or later), CentOS/RHEL/OEL 7.2
- docker 1.12 or later
- /boot/symvers-\`uname -r\`.gz on docker host
- ansible 2.2.1 or later
- Oracle 12c Release 2 (12.2) Clusterware and Database software 
- 1core CPU per container and  4GB Memory per container



## Attention
Each container run with privileged flag (Each container enables to access to all devices on the Docker host ). 

It may be dangerous.


## Setup
### 1. create swap
    #dd if=/dev/zero of=/swapfile bs=4096 count=1M
    #mkswap /swapfile
    #echo "/swapfile none swap sw 0 0" >> /etc/fstab
    #swapon -a
### 2. install prerequisite packages
    ##CentOS 7.3
    #yum install -y epel-release
    #yum install -y python-pip openssl-devel gcc python-devel git unzip --enablerepo=epel
    
    ##ubuntu 16.04 
    #apt-get update
    #apt-get install -y git python-dev python-pip libssl-dev unzip
### 3. install ansible
    #pip install pip --upgrade
    #pip install ansible    
### 4. install docker
    #curl -fsSL https://get.docker.com/ | sh
### 5. enable docker service
    ### CentOS7 / ubuntu 16.04
    #systemctl start docker 
    #systemctl enable docker
### 6. download Oracle 12c Release 2 (12.2) Clusterware and Database software and locate /media
    # ls -al  /media
    total 6297260
    -rw-r--r-- 1 root root 3453696911 Mar 28 12:30 linuxx64_12201_database.zip
    -rw-r--r-- 1 root root 2994687209 Mar 28 12:31 linuxx64_12201_grid_home.zip
### 7. cloning an Repository
    #git clone https://github.com/s4ragent/rac_on_xx

## Usage
execute dockeruntil.sh   (no option create 3-nodes RAC)

    ##create 3-nodes RAC#
    #cd rac_on_xx/docker
    #bash dockerunil.sh runall

if you want to build 5-nodes RAC

    ##create 5-nodes RAC#
    #cd rac_on_xx/docker
    #bash dockerunil.sh runall 5

if you want to log in node001

    #docker exec -ti node001 /bin/bash

if you want to execute oracle commands on node001 (ex. crsctl status res -t)

    #docker exec -ti node001 /u01/app/12.1.0/grid/bin/crsctl status res -t

if you want to stop first container

    #bash dockerunil.sh stop 1

if you want to stop storage container

    #bash dockerunil.sh stop storage

and restart first container

    #bash dockerunil.sh start 1
    
if you want to start all containers

    #bash dockerunil.sh startall

if you want to delete all containers

    #bash dockerunil.sh deleteall

## Licence
[MIT]

## Todo
- Docker container run without privileged flags
- docker save

## Author
@s4r_agent

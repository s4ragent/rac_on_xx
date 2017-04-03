rac_on_xx/azure
====

 Oracle RAC on azure

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


## Requirement
- Microsoft Azure Account
- Microsoft Azure CLI 2.0
- ansible 2.2.1 or later
- Oracle 12c Release 2 (12.2) Clusterware and Database software 



## Setup
### 1. create Windows Azure account
    See https://azure.microsoft.com/en-us/free/?b=17.09b
### 2. install prerequisite packages
    ##CentOS 7.3
    #yum install -y epel-release
    #yum install -y python-pip openssl-devel gcc python-devel libffi-devel git unzip --enablerepo=epel
    
    ##ubuntu 16.04 
    #apt-get update
    #apt-get install -y git python-dev libffi-devpython-pip libssl-dev libffi-dev build-essential unzip
### 3. install ansible
    #pip install pip --upgrade
    #pip install ansible    
### 4. install Azure CLI
    #curl -L https://aka.ms/InstallAzureCli | bash
### 5. Log in with Azure CLI 2.0
    see https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli
### 6. download Oracle 12c Release 2 (12.2) Clusterware and Database software and locate them on /media
    # ls -al  /media
    total 6297260
    -rw-r--r-- 1 root root 3453696911 Mar 28 12:30 linuxx64_12201_database.zip
    -rw-r--r-- 1 root root 2994687209 Mar 28 12:31 linuxx64_12201_grid_home.zip
### 7. cloning an Repository
    #git clone https://github.com/s4ragent/rac_on_xx

## Usage
execute azureutil.sh   (azureutil.sh execute ansible-playbook and build RAC cluster. no option create 3-nodes RAC)

    ##create 3-nodes RAC#
    #cd rac_on_xx/azure
    #bash azureutil.sh runall

if you want to build 5-nodes RAC

    ##create 5-nodes RAC#
    #cd rac_on_xx/azure
    #bash azureutil.sh runall 5

if you want to log in node001

    #bash azureutil.sh ssh 1

if you want to execute oracle commands on node001 (ex. crsctl status res -t)

    #sudo /u01/app/12.2.0/grid/bin/crsctl status res -t

if you want to stop first container

    #bash azureutil.sh stop 1

if you want to stop storage container

    #bash azureutil.sh stop storage

and restart first container

    #bash azureutil.sh start 1
    
if you want to start all containers

    #bash azureutil.sh startall

if you want to delete all containers

    #bash azureutil.sh deleteall

## Licence
[MIT]

## Author
@s4r_agent

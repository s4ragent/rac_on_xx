rac_on_xx/ec2
====

 Oracle RAC on Amazon EC2

## Description
- basic infomation

|||
|-----|-----|
|OS|Oracle Linux 7.x|
|Storage|NFS4 with Flex ASM|
|L2 Network emulation|vxlan|
|DNS|dnsmasq on each instance|

- Network infomation (e.g. 3-nodes RAC)

|hostname/instance name/vip|eth0|vxlan0(public)|vxlan1(internal)|vxlan2(asm)|
|--------|--------|-------|-------|-------|
|storage|10.xx.xx.xx|-|-|-|
|node001|10.xx.xx.xx|192.168.0.51|192.168.100.51|192.168.200.51|
|node002|10.xx.xx.xx|192.168.0.52|192.168.100.52|192.168.200.52|
|node003|10.xx.xx.xx|192.168.0.53|192.168.100.53|192.168.200.53|
|node001.vip|-|192.168.0.151|-|-|
|node002.vip|-|192.168.0.152|-|-|
|node003.vip|-|192.168.0.152|-|-|
|scan1.vip|-|192.168.0.31|-|-|
|scan2.vip|-|192.168.0.32|-|-|
|scan3.vip|-|192.168.0.33|-|-|


- Storage infomation 

|Diskgroup name|use|asm device path|redundancy|size(GB)|size(GB)(e.g. 3-nodes RAC)|
|--------|--------|-------|-------|-------|-------|
|VOTE|ocr and voting disk|/u01/oradata/vote.img|external| 5120 + ( num_of_nodes * 1024 )|8192|
|DATA|Database files|/u01/oradata/data.img|external| 5120 + ( num_of_nodes * 1024 ) |8192|
|FRA|flash recovery area|/u01/oradata/fra.img|external|5120|5120|

## Requirement
- Oracle 12c Release 1 (12.1) Clusterware and Database software
- AWS account
- aws cli
- ansible 2.2.1 or later

## Install
>git clone https://github.com/s4ragent/rac_on_xx

## Usage
download Oracle 12c Release 1 (12.1) Clusterware and Database software on ansible host

    #mkdir -p /media
    #download  Oracle 12c Release 1 (12.1) Clusterware and Database software
    $ ls -al /media
    drwxr-xr-x.  2 root root       4096 Feb  7 01:07 .
    drwxr-xr-x. 18 root root       4096 Jan 10 07:35 ..
    -rw-r--r--.  1 root root 1673544724 Jul 11  2014 V46095-01_1of2.zip
    -rw-r--r--.  1 root root 1014530602 Jul 11  2014 V46095-01_2of2.zip
    -rw-r--r--.  1 root root 1747043545 Jul 11  2014 V46096-01_1of2.zip
    -rw-r--r--.  1 root root  646972897 Jul 11  2014 V46096-01_2of2.zip


If you need, change edit ec2/vars.yml to change region and image-id
    
    #for oregon region
    #REGION: "us-west-2"
    #INSTANCE_OPS: "--image-id ami-4a637f2b"
    #for tokyo region
    REGION: "ap-northeast-1"
    INSTANCE_OPS: "--image-id ami-65e0c80b"
    
Execute ec2util.sh   (no option create 3-nodes RAC)

    ##create 3-nodes RAC#
    #cd rac_on_xx/gce
    $bash ec2util.sh runall

If you want to build 5-nodes RAC

    ##create 5-nodes RAC#
    $cd rac_on_xx/gce
    $bash ec2util.sh runall 5

if you want to stop first instance

    $bash ec2util.sh stop 1

if you want to stop nfs instance

    $bash ec2util.sh stop storage

and restart first node

    $bash aec2util.sh start 1
    
if you want to start all node

    $bash ec2util.sh startall

if you want to delete all node

    $bash ec2util.sh deleteall

## Licence
MIT


## Author
@s4r_agent


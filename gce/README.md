rac_on_xx/gce
====

 Oracle RAC on Google Compute Engine

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
|nfs|10.xx.xx.xx|-|-|-|
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

## Demo (6-nodes RAC on Google Compute Engine)
![crsctl]()

## Requirement
- Google Cloud Platform Account
- Google Cloud SDK
- ansible 2.0 or later

## Install
>git clone https://github.com/s4ragent/rac_on_xx

## Usage

execute gceuntil.sh   (no option create 3-nodes RAC)

    ##create 3-nodes RAC#
    #cd rac_on_xx/gce
    #bash gceutil.sh preinstall

if you want to build 5-nodes RAC

    ##create 5-nodes RAC#
    #cd rac_on_xx/gce
    #bash gceutil.sh preinstall 5

and ssh port forwarding 33
    
    ##
    bash gceutil.sh ssh nfs


and access http://localhost:1234  on ansible host


    ##
    firefox http://localhost:1234/




if you want to stop first instance

    #bash gceutil.sh stop 1

if you want to stop nfs instance

    #bash gceutil.sh stop nfs

and restart first node

    #bash gceutil.sh start 1
    
if you want to start all node

    #bash gceutil.sh startall

if you want to delete all node

    #bash gceutil.sh deleteall

## Licence
[MIT](https://github.com/tcnksm/tool/blob/master/LICENCE)


## Author
@s4r_agent

rac_on_xx/kubernetes
====

 Oracle RAC on kubernetes

## Description
- basic infomation

|||
|-----|-----|
|OS|Oracle Linux 7.x|
|Storage|NFS4 with Flex ASM|
|L2 Network emulation|vxlan|
|DNS|dnsmasq on each pod|

- kubernetes infomation

|||
|-----|-----|
|namespace|raconxx|
|clusterdomain|cluster.local|
|subdomain|sub|
|Volume|Dynamic Volume Provisioning|

- Network infomation (e.g. 3-nodes RAC)

|pod name/vip|eth0|vxlan0(public)|vxlan1(internal)|vxlan2(asm)|
|--------|--------|-------|-------|-------|
|storage|10.x.x.x|-|-|-|
|node001|10.x.x.x|192.168.0.51|192.168.100.51|192.168.200.51|
|node002|10.x.x.x|192.168.0.52|192.168.100.52|192.168.200.52|
|node003|10.x.x.x|192.168.0.53|192.168.100.53|192.168.200.53|
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

## Demo (3-nodes RAC on kubernetes)
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/k8s/Screenshot_20171207-175650_1_1.jpg)
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/k8s/Screenshot_20171207-175654_1.jpg)


## Requirement
- GKE(Google Kubernetes Engine) or ACS(Azure Container Service) 
- Google Cloud SDK(GKE) or Azure CLI 2.0(ACS) 
- Oracle 12c Release 2 (12.2) Clusterware and Database software
- 4 worker nodes　 
- 2core CPU per node and 8GB Memory per node



## Setup
### 1. Deploy Kubernetes cluster
    ##GKE
    see https://cloud.google.com/kubernetes-engine/docs/quickstart?hl=en 
    
    ##ACS 
    see https://docs.microsoft.com/en-us/azure/container-service/kubernetes/container-service-kubernetes-walkthrough
### 2. download Oracle 12c Release 2 (12.2) Clusterware and Database software and locate them on /media
    # ls -al  /media
    total 6297260
    -rw-r--r-- 1 root root 3453696911 Mar 28 12:30 linuxx64_12201_database.zip
    -rw-r--r-- 1 root root 2994687209 Mar 28 12:31 linuxx64_12201_grid_home.zip
### 3. cloning an Repository
    #git clone https://github.com/s4ragent/rac_on_xx

### 4. edit k8s/vars.yml (for GKE)

## Usage
execute k8s.utilsh   (k8s.sh execute kubectl command)

    ##create pod (nfs/dbserber)
    #cd rac_on_xx/k8s
    #bash k8s.sh runpod
    
    ##Copy Database software
    #bash k8s.sh copymedia

    ##log in node001 and install Clusterware and Database
    #kubectl exec --namespace raconxx -ti node001 /bin/bash
    #cd /root/rac_on_xx/k8s
    #bash k8sutil.sh install 


if you want to delete all pod and volumes

    #bash k8s.sh deleteall

## Licence
[MIT]


## Author
@s4r_agent

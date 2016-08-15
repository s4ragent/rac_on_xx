rac_on_xx/docker
====

 Oracle RAC on docker

## Description
|-|eth0|vxlan0|vxlan1|vxlan2|
|--------|--------|-------|-------|-------|
|nfs|10.153.0.50|-|-|-|
||||||
||||||
||||||
||||||
||||||
||||||
||||||
||||||
||||||

## Demo
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/docker/rac_on_docker_01.png)
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/docker/rac_on_docker_02.png)
![crsctl](https://github.com/s4ragent/misc/blob/master/rac_on_xx/docker/rac_on_docker_03.png)
## Requirement
- Linux Kernel 3.18 or CentOS/RHEL/OEL 7.2 
- docker 1.12
- ansible 2.0 or lateor
- Oracle 12c Release 1 (12.1) Clusterware and Database software 

## Install
>git clone https://github.com/s4ragent/rac_on_xx

## Usage
download/unzip Oracle 12c Release 1 (12.1) Clusterware and Database software on docker host

    #mkdir -p /media
    #unzip linuxamd64_12102_database_1of2.zip -d /media
    #unzip linuxamd64_12102_database_2of2.zip -d /media
    #unzip linuxamd64_12102_grid_1of2.zip -d /media
    #unzip linuxamd64_12102_grid_2of2.zip -d /media
     
    #ls -al /media
    total 16
    drwxr-xr-x 4 root root 4096 May  1 21:56 .
    drwxr-xr-x 3 root root 4096 May  1 21:53 ..
    drwxr-xr-x 7 root root 4096 Jul  7  2014 database
    drwxr-xr-x 7 root root 4096 Jul  7  2014 grid
    
execute dockeruntil.sh  

    #cd rac_on_xx/docker
    #bash dockeruntil.sh runall

if you want to stop first container

    #bash dockeruntil.sh stop 1

and restart first container

    #bash dockeruntil.sh start 1
    
if you reboot container

    #bash dockeruntil.sh startall

if you want to delete all container

    #bash dockeruntil.sh deleteall


## Author
@s4r_agent

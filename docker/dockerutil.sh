#!/bin/bash
source ../common.sh

IMAGE="s4ragent/rac_on_xx:OEL7"
BRNAME="racbr"
#CAP_OPS="--cap-add=NET_ADMIN"
CAP_OPS="--privileged=true"

createnetwork(){
    SEGMENT=`echo $NFS_SERVER | grep -Po '\d{1,3}\.\d{1,3}\.'`
    DOCKERSUBNET="${SEGMENT}0.0/16"
    #docker network create -d --subnet=192.168.0.0/16
    docker network create -d bridge --subnet=$DOCKERSUBNET racbr
}

run(){
    docker run 
}

case "$1" in
  "createnetwork" ) shift;createnetwork $*;;
  "runall" ) shift;runall $*;;
  "run" ) shift;run $*;;
  "startall" ) shift;startall $*;;
  "deleteall" ) shift;deleteall $*;;
  "stopall" ) shift;stopall $*;;
  * ) echo "Ex " ;;
esac

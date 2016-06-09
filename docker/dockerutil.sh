#!/bin/bash
source ./common.sh

createnetwork(){
    SEGMENT=`echo $NFS_SERVER | grep -Po '\d{1,3}\.\d{1,3}\.'`
    DOCKERSUBNET="${SEGMENT}0.0/16"
    #docker network create -d --subnet=192.168.0.0/16
    docker network create -d --subnet bridge $DOCKERSUBNET RAC
}



case "$1" in
  "createnetwork" ) shift;createnetwork $*;;
  "runall" ) shift;startall $*;;
  "startall" ) shift;startall $*;;
  "deleteall" ) shift;deleteall $*;;
  "stopall" ) shift;stopall $*;;
  * ) echo "Ex " ;;
esac

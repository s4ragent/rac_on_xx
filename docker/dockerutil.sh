#!/bin/bash
source ./common.sh

createnetwork(){
    docker network create -d bridge my-bridge-network
}



case "$1" in
  "createnetwork" ) shift;createnetwork $*;;
  "runall" ) shift;startall $*;;
  "startall" ) shift;startall $*;;
  "deleteall" ) shift;deleteall $*;;
  "stopall" ) shift;stopall $*;;
  * ) echo "Ex " ;;
esac

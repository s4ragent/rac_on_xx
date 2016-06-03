#!/bin/bash
source ./common.sh


	rm -rf $WORK/id_rsa*
	rm -rf $WORK/known_hosts
	ssh-keygen -t rsa -P "" -f $WORK/id_rsa
    
	for i in `seq 1 $1`; do
      		nodename=`getnodename $i`
      		nodeip=`getip 0 real $i`
      		ssh-keyscan -T 180 -t rsa $nodename >> ./known_hosts
      		ssh-keyscan -T 180 -t rsa $nodeip >> ./known_hosts
  done
  
  
  

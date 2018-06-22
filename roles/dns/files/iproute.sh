#!/bin/bash
myip=`ip addr show ens3 | grep 'inet ' | awk -F '[/ ]' '{print $6}'`
ip route add 169.254.0.2/32 via $myip dev ens3
ip route add 169.254.169.254/32 via $myip dev ens3
ip route del 169.254.0.0/16 dev ens3

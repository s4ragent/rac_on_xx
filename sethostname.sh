#!/bin/bash
source ./common.sh

MyNumber=`getmynumber`
nodename=`getnodename $MyNumber`

cat >> /etc/dhcp/dhclent-eth0.conf <<EOF
supersede host-name $nodename.${DOMAIN_NAME},domain-name ${DOMAIN_NAME};
EOF

touch /root/hostnamedone
reboot




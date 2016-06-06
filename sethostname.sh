#!/bin/bash
source ./common.sh

MyNumber=`getmynumber`
nodename=`getnodename $MyNumber`

cat >> /etc/dhclient.conf <<EOF
supersede host-name $nodename.${DOMAIN_NAME},domain-name ${DOMAIN_NAME};
EOF

touch /root/hostnamedone





#!/bin/bash
cat >  /etc/NetworkManager/conf.d/dns.conf <<EOF
[main]
dns=dnsmasq
EOF

cat>  /etc/NetworkManager/dnsmasq.d/hosts << EOF
addn-hosts=/etc/addn-hosts
EOF




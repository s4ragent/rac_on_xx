#!/bin/bash
source ./common.sh
cat >  /etc/NetworkManager/conf.d/dns.conf <<EOF
[main]
dns=dnsmasq
EOF

cat>  /etc/NetworkManager/dnsmasq.d/hosts << EOF
addn-hosts=/etc/addn-hosts
EOF

getip 0 scan >> /etc/addn-hosts
for i in `seq 1 64`; do
  nodename=`getnodename $i`
  echo "`getip 0 real $i` $nodename".${DOMAIN_NAME}" $nodename" >> /etc/addn-hosts
  vipnodename=$nodename"-vip"
  echo "`getip 0 vip $i` $vipnodename".${DOMAIN_NAME}" $vipnodename" >> /etc/addn-hosts
done

systemctl restart NetworkManager


#!/bin/bash
source ./common.sh

#cat << EOF >/etc/addn-hosts
#127.0.0.1       localhost
#::1     localhost ip6-localhost ip6-loopback
#fe00::0 ip6-localnet
#ff00::0 ip6-mcastprefix
#ff02::1 ip6-allnodes
#ff02::2 ip6-allrouters
#EOF
#sed -i.bak 's:/etc/hosts:/etc/addn-hosts:g' /lib64/libnss_files.so.2

getip 0 scan >> /etc/addn-hosts
for i in `seq 1 64`; do
  nodename=`getnodename $i`
  echo "`getip 0 real $i` $nodename".${DOMAIN_NAME}" $nodename" >> /etc/addn-hosts
  vipnodename=$nodename"-vip"
  echo "`getip 0 vip $i` $vipnodename".${DOMAIN_NAME}" $vipnodename" >> /etc/addn-hosts
done

cat << EOT >> /etc/dnsmasq.conf
listen-address=127.0.0.1
resolv-file=/etc/resolv.dnsmasq.conf
conf-dir=/etc/dnsmasq.d
user=root
addn-hosts=/etc/addn-hosts
EOT

cat << EOT >> /etc/resolv.dnsmasq.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOT

systemctl enable dnsmasq
systemctl start dnsmasq

#!/bin/bash
#!/bin/bash
source ./common.sh

MyNumber=`getmynumber`
nodename=`getnodename $MyNumber`

cat >/usr/local/bin/sethostname.init << EOF
#!/bin/bash
set_hostname()
{
  hostnamectl set-hostname $nodename.${DOMAIN_NAME}
  echo "search ${DOMAIN_NAME}" > /etc/resolv.conf
  echo "nameserver 127.0.0.1" >> /etc/resolv.conf
  echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
  echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
}
EOF

cat >>/usr/local/bin/sethostname.init << 'EOF'
case "$1" in
  start)
    shift;set_hostname $*;;
esac
EOF
chmod 0700 /usr/local/bin/sethostname.init
bash /etc/NetworkManager/dispatcher.d/30_hostname vxlan0 up

touch /root/hostnamedone

#!/bin/bash
source ./common.sh

MyNumber=`getmynumber`
nodename=`getnodename $MyNumber`

cat >/etc/NetworkManager/dispatcher.d/30_hostname << EOF
#!/bin/bash
set_hostname()
{
  hostnamectl set-hostname $nodename.${DOMAIN_NAME}
}
EOF

cat >>/etc/NetworkManager/dispatcher.d/30_hostname << 'EOF'
case "$1" in
  vxlan0)
    shift;set_hostname $*;;
esac
EOF
chmod 0700 /etc/NetworkManager/dispatcher.d/30_hostname
bash /etc/NetworkManager/dispatcher.d/30_hostname vxlan0 up

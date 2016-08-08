#!/bin/bash
PreRPM=`rpm -qa | grep xrdp | wc -l`
if [ $PreRPM -eq 0 ]; then
  rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  #yum -y --enablerepo=epel groupinstall Xfce
  yum -y groupinstall "Server With GUI"
  yum -y install vnc-server xrdp screen
fi

systemctl enable xrdp
chcon -t bin_t /usr/sbin/xrdp /usr/sbin/xrdp-sesman
sed -i -e 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini
systemctl start xrdp

#cat > /etc/skel/.Xclients << EOF
##!/bin/bash
#exec xfce4-session
#EOF
#chmod +x /etc/skel/.Xclients

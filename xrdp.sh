#!/bin/bash
curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
yum -y --enablerepo=epel groupinstall Xfce
yum -y install vnc-server
yum -y install xrdp
systemctl enable xrdp
chcon -t bin_t /usr/sbin/xrdp /usr/sbin/xrdp-sesman
sed -i -e 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini

cat << 'EOF' | sudo tee /etc/skel/.Xclients
#!/bin/bash
exec xfce4-session
EOF
chmod +x /etc/skel/.Xclients

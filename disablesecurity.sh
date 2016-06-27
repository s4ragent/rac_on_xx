#!/bin/bash
###selinux disable####
sed -i  's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

### enable root ssh login
sed -i  's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
### disable password login
sed -i  's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
systemctl enable sshd

##disable firewalled##
systemctl stop firewalld
systemctl disable firewalled

touch /root/disablesecuritydone

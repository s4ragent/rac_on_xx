#!/bin/bash
###selinux disable####
sed -i  's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

### root ssh/
sed -i  's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

##disable firewalled##
systemctl stop firewalld
systemctl disable firewalled

touch /root/disablesecuritydone

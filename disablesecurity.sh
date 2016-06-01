#!/bin/bash
###selinux disable####
sed -i  's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

##disable firewalled##
systemctl stop firewalld
systemctl disable firewalled

touch /root/disablesecuritydone

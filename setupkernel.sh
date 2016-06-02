#!/bin/bash
source ./common.sh

sed -i 's/oracle/#oracle/' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
#this is for oracle install#
oracle - nproc 16384
oracle - nofile 65536
oracle soft stack 10240
oracle hard  memlock  3145728
grid - nproc 16384
grid - nofile 65536
grid soft stack 10240
EOF

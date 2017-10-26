#!/bin/bash
source ~/.bash_profile
sqlplus /nolog <<EOF
conn /as sysdba
CREATE USER tpcc IDENTIFIED BY tpcc;
GRANT connect, resource TO tpcc;
exit
EOF

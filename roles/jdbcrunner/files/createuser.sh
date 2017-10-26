#!/bin/bash
source ~/.bash_profile
export ORACLE_SID=$1
echo "SID:$ORACLE_SID"
echo ""
sqlplus /nolog <<EOF
conn /as sysdba
CREATE USER tpcc IDENTIFIED BY tpcc;
GRANT connect, resource TO tpcc;
exit
EOF

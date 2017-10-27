#!/bin/bash
source ~/.bash_profile
export ORACLE_SID=$1
echo "SID:$ORACLE_SID"
echo ""
sqlplus /nolog <<EOF
conn /as sysdba
DROP USER tpcc cascade;
CREATE USER tpcc IDENTIFIED BY tpcc
DEFAULT TABLESPACE USERS
QUOTA UNLIMITED ON USERS
TEMPORARY TABLESPACE TEMP;
GRANT connect, resource,create table,create index TO tpcc;
exit
EOF

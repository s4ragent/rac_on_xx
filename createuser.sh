#!/bin/bash
source ./common.sh

  ###delete user ###
  userdel -r oracle
  userdel -r grid
  groupdel dba
  groupdel oinstall
  groupdel oper
  groupdel asmadmin
  groupdel asmdba
  groupdel asmoper

##create user/group####
  groupadd -g 601 oinstall
  groupadd -g 602 dba
  groupadd -g 603 oper
  groupadd -g 2001 asmadmin
  groupadd -g 2002 asmdba
  groupadd -g 2003 asmoper
  useradd -u 501 -m -g oinstall -G dba,oper,asmdba -d /home/oracle -s /bin/bash -c"Oracle Software Owner" oracle
  useradd -u 2001 -m -g oinstall -G asmadmin,asmdba,asmoper -d /home/grid -s /bin/bash -c "Grid Infrastructure Owner" grid

### edit bash &bashrc ###
   cat >> /home/oracle/.bashrc <<'EOF'
#this is for oracle install#
if [ -t 0 ]; then
   stty intr ^C
fi
EOF

  cat >> /home/grid/.bashrc <<'EOF'
#this is for oracle install#
if [ -t 0 ]; then
   stty intr ^C
fi
EOF

  cat >> /home/oracle/.bash_profile <<EOF
### for oracle install ####
export ORACLE_BASE=${ORA_ORACLE_BASE}
export ORACLE_HOME=${ORA_ORACLE_HOME}
EOF

  cat >> /home/oracle/.bash_profile <<'EOF'
export TMPDIR=/tmp
export TEMP=/tmp
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/jdk/bin:${PATH}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
EOF

  cat >> /home/grid/.bash_profile <<EOF
### for grid install####
export ORACLE_BASE=${GRID_ORACLE_BASE}
export ORACLE_HOME=${GRID_ORACLE_HOME}
EOF

  cat >> /home/grid/.bash_profile <<'EOF'
export TMPDIR=/tmp
export TEMP=/tmp
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/jdk/bin:${PATH}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
EOF

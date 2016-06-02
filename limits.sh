#!/bin/bash
source ./common.sh
cp /etc/security/limits.d/${LimitsConf}.conf /etc/security/limits.d/${LimitsConf}-grid.conf
sed -i 's/oracle/grid/' /etc/security/limits.d/${LimitsConf}-grid.conf

cat > /etc/security/limits.d/20-nproc.conf << 'EOF'
root       soft    nproc     unlimited
* - nproc 16384
EOF

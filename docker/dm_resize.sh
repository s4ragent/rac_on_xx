#!/bin/bash
systemctl stop docker
rm -rf /var/lib/docker
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/storage.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --storage-opt dm.basesize=100G --storage-opt dm.loopdatasize=1024G --storage-opt dm.loopmetadatasize=4G --storage-opt dm.fs=xfs --storage-opt dm.blocksize=512K
EOF
systemctl daemon-reload
systemctl start docker

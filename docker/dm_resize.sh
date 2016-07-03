#!/bin/bash
systemctl stop docker
rm -rf /var/lib/docker
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/storage.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --storage-opt dm.basesize=50G --storage-opt dm.loopdatasize=200G --storage-opt dm.loopmetadatasize=4G --storage-opt dm.fs=xfs --storage-opt dm.blocksize=512
EOF
systemctl daemon-reload
systemctl start docker

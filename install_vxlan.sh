#!/bin/bash
cp ./vxlan.service /etc/systemd/system/vxlan.service
cp ./vxlan.init /usr/local/bin/vxlan.init
chmod 0700  /usr/local/bin/vxlan.init
systemctl enable vxlan.service

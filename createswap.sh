#!/bin/bash
#crete swap
dd if=/dev/zero of=/var/tmp/swap.img bs=1M count=8192
mkswap /var/tmp/swap.img
sh -c 'echo "/var/tmp/swap.img swap swap defaults 0 0" >> /etc/fstab'
swapon -a

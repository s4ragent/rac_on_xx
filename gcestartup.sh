#!/bin/bash
yum -y install git
git clone https://github.com/s4ragent/rac_on_gce
bash rac_on_gce/createswap.sh
bash rac_on_gce/centos72oel7.sh

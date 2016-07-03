#!/bin/bash

LOG="`date "+%Y%m%d-%H%M%S"`.log"
bash dockerutil.sh runall silent >$LOG  2>&1
for i in `seq 1 $1`
do
    LOG="`date "+%Y%m%d-%H%M%S"`.log"
    bash dockerutil.sh deleteandrun silent >$LOG  2>&1
    #docker exec -ti node001 bash -c "cd /root/rac_on_xx && bash ./racutil.sh deconfig" >$LOG  2>&1
    #docker exec -ti node001 bash -c "cd /root/rac_on_xx && bash ./racutil.sh gridrootsh " >$LOG  2>&1
    #docker exec -ti node001 bash -c "cd /root/rac_on_xx && bash ./racutil.sh gridstatus " >$LOG  2>&1
done

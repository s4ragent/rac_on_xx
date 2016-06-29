#!/bin/bash
for i in `seq 1 $1`
do
    LOG="`date "+%Y%m%d-%H%M%S"`.log"
    #bash dockerutil.sh deleteandrun silent >$LOG  2>&1
    docker exec -ti $NODENAME bash -c "cd /root/rac_on_xx && bash ./racutil.sh deconfig" >$LOG  2>&1
    docker exec -ti $NODENAME bash -c "cd /root/rac_on_xx && bash ./racutil.sh gridrootsh " >$LOG  2>&1
done
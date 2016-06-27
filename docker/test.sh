#!/bin/bash
for i in `seq 1 $1`
do
    bash dockerutil.sh deleteandrun silent > `date "+%Y%m%d-%H%M%S"`.log 2>&1
done
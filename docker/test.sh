#!/bin/bash
for i in `seq 1 $1`
do
    bash dockerutil.sh deleteandrun silent > `date`.log 2>&1
done
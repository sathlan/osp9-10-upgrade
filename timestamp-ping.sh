#!/usr/bin/bash

step=${1?:"give the current step"}

for i in ~/current_state_*.log; do
    echo STEP:$step:$(date) >> $i
done
for i in ~/ping_results*.log; do
    echo STEP:$step:$(date) >> $i
done

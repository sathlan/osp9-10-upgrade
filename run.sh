#!/usr/bin/bash

set -eux

script="${1:?You must provide the script to run}"
log=${script}.log
cpt=1
while [ cpt -le 20 -a -e $log ] ; do
    log=${script}.${cpt}.log
    cpt=$((cpt+1))
done

nohup ./${script} > $log &
disown
tail -f $log

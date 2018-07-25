#!/usr/bin/bash

set -eux

script="${1:?You must provide the script to run}"
log=${script//\.\//_}
log=${HOME}/${log//\//_}.log

cpt=1
while [ $cpt -le 20 -a -e $log ] ; do
    log=${log}.${cpt}.log
    cpt=$((cpt+1))
done

date > ${log}-start
nohup ./${script} > $log &
disown

echo tail -f $log

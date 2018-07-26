#!/usr/bin/bash

set -eux

. ${HOME}/stackrc

./timestamp-ping.sh 45-ceph-upgrade-begin
for i in $(cat ~/compute-ip.txt); do
    grep -q ${i} ~/.ssh/known_hosts || ssh-keyscan -t rsa ${i} >> ~/.ssh/known_hosts
done
for i in $(jq -r '.[] | select(.Name | contains("ceph"))|.Name' ~/server.json); do
    echo "UPGRADING $i"
    upgrade-non-controller.sh --upgrade $i
    echo "DONE $i"
done
./timestamp-ping.sh 45-ceph-upgrade-end

#!/usr/bin/bash

. ~/overcloudrc
set -eux

suffix="${1:?Please give a pre/post suffix}"
nova service-list > ~/${suffix}-info.log
neutron agent-list >> ~/${suffix}-info.log

. ~/stackrc
if [ ! -e ~/server.json ]; then
    openstack server list -f json > ~/server.json
fi

if [ ! -e ~/controller-ip.txt ]; then
    jq -r '.[] | select(.Name | contains("controller"))|.Networks' ~/server.json | cut -d= -f2 > ~/controller-ip.txt
fi
if [ ! -e ~/compute-ip.txt ]; then
    jq -r '.[] | select(.Name | contains("compute"))|.Networks' ~/server.json | cut -d= -f2 > ~/compute-ip.txt
fi

# bz 1595315
suffix=pre-pre
for i in $(cat controller-ip.txt); do
    echo -ne "$i\n\n" >> ~/${suffix}-info.log
    ssh heat-admin@$i \
        sudo bash -c "'ls -lrthd /var/log/cinder && ls -lrth /var/log/cinder/'" >> ~/${suffix}-info.log
    echo >> ${suffix}-info.log
done

for i in $(cat controller-ip.txt compute-ip.txt); do
    ssh heat-admin@$i \
        sudo bash -c "journalctl -u" >> ~/os-$i.log
done

sudo yum install -y strace vim tcpdump

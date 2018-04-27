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
if [ ! -e ~/compute-ip.txt]; then
    jq -r '.[] | select(.Name | contains("compute"))|.Networks' ~/server.json | cut -d= -f2 > ~/compute-ip.txt
fi
sudo yum install -y strace vim tcpdump

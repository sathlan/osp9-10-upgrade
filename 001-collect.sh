#!/usr/bin/bash

. ~/overcloudrc
set -eux

suffix="${1:?Please give a pre/post suffix}"
nova service-list > ~/${suffix}-info.log
neutron agent-list >> ~/${suffix}-info.log

. ~/stackrc
openstack server list -f json > ~/server.json

jq -r '.[] | select(.Name | contains("controller"))|.Networks' ~/server.json | cut -d= -f2 > ~/controller-ip.txt
jq -r '.[] | select(.Name | contains("compute"))|.Networks' ~/server.json | cut -d= -f2 > ~/compute-ip.txt

sudo yum install -y strace vim tcpdump

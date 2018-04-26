#!/usr/bin/bash
set -eux

yum repolist -v enabled
sudo systemctl list-units 'openstack-*'

# You need Red-Hat 7.3, see
# https://bugzilla.redhat.com/show_bug.cgi?id=1373140
sudo rhos-release 10
sudo yum-config-manager --disable 'rhelosp-9*'
yum repolist -v enabled

env

step="$(basename $0)"
export CURRENT_STEP="${step%.sh}"

sudo systemctl stop 'openstack-*' 'neutron-*' httpd
sudo yum update -y python-tripleoclient

nohup openstack undercloud upgrade > ${CURRENT_STEP}.log

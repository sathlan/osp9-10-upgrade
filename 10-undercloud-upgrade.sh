#!/usr/bin/bash
set -eux

./timestamp-ping.sh 10-undercloud-upgrade-begin
yum repolist -v enabled
sudo systemctl list-units 'openstack-*'

# You need Red-Hat 7.3, see
# https://bugzilla.redhat.com/show_bug.cgi?id=1373140
sudo rhos-release 10
sudo yum-config-manager --disable 'rhelosp-9*'
yum repolist -v enabled

env

sudo systemctl stop 'openstack-*' 'neutron-*' httpd
sudo yum update -y python-tripleoclient

openstack undercloud upgrade
./timestamp-ping.sh 10-undercloud-upgrade-end

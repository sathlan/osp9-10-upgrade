#!/usr/bin/bash
set -eux

. ${HOME}/stackrc

export DEPLOY_ENV_YAML=' /usr/share/openstack-tripleo-heat-templates/environments/major-upgrade-pacemaker-converge.yaml'

./timestamp-ping.sh 60-converge-begin
exec ${HOME}/overcloud-deploy.sh -e $DEPLOY_ENV_YAML
./timestamp-ping.sh 60-converge-end

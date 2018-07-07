#!/usr/bin/bash
set -eux

. ${HOME}/stackrc

export DEPLOY_ENV_YAML='/usr/share/openstack-tripleo-heat-templates/environments/major-upgrade-pacemaker.yaml'

./timestamp-ping.sh 40-controller-upgrade-begin
${HOME}/overcloud-deploy.sh -e $DEPLOY_ENV_YAML
./timestamp-ping.sh 40-controller-upgrade-end

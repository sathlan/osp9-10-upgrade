#!/usr/bin/bash
set -eux

. ${HOME}/stackrc

export DEPLOY_ENV_YAML='/usr/share/openstack-tripleo-heat-templates/environments/major-upgrade-pacemaker.yaml'

exec ${HOME}/overcloud-deploy.sh -e $DEPLOY_ENV_YAML

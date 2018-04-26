#!/usr/bin/bash
set -eux

. ${HOME}/stackrc

export DEPLOY_ENV_YAML=' /usr/share/openstack-tripleo-heat-templates/environments/major-upgrade-ceilometer-wsgi-mitaka-newton.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/updates/update-from-overcloud-compute-hostnames.yaml'

step="$(basename $0)"
export CURRENT_STEP="${step%.sh}"

#${HOME}/support/pcs_resource_cleanup.sh

exec ${HOME}/overcloud-deploy.sh -e $DEPLOY_ENV_YAML

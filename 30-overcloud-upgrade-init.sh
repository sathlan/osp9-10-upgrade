#!/usr/bin/bash
set -eux

. ${HOME}/stackrc

cat > ~/overcloud-repos.yaml <<EOF
parameter_defaults:
  UpgradeInitCommand: |
    set -e
    yum localinstall -y http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm
    rhos-release 10
EOF

env
export DEPLOY_ENV_YAML='/usr/share/openstack-tripleo-heat-templates/environments/major-upgrade-pacemaker-init.yaml -e /home/stack/overcloud-repos.yaml'

exec ${HOME}/overcloud-deploy.sh -e $DEPLOY_ENV_YAML

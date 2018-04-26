#!/usr/bin/bash

set -eux

sed -E -e '/log-file overcloud_deployment/d' \
    -e 's|/home/stack/virt/extra_templates.yaml \\|/home/stack/virt/extra_templates.yaml $@|;' \
    ~/overcloud_deploy.sh > ~/overcloud-deploy.sh
chmod a+x ~/overcloud-deploy.sh

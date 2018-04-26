#!/usr/bin/bash

if [ -n "$1" ]; then
    sudo yum remove -y openstack-tripleo-heat-templates
    sudo yum install -y openstack-tripleo-heat-templates instack-undercloud openstack-tripleo-common openstack-tripleo-heat-templates-compat python-tripleoclient
fi
REVIEWS="${REVIEWS} 560855"     # l3agentfailover
#REVIEWS="${REVIEWS} 563650"     # fqdn_canonical

for review in $REVIEWS; do
    if [ -e  $review.patch ]; then
        cp $review.patch $review.patch.$$
    fi
    curl -4 https://review.openstack.org/changes/${review}/revisions/current/patch?download | \
        base64 -d > $review.patch
    cat $review.patch | sudo patch -d "/usr/share/openstack-tripleo-heat-templates" -p1
done

bash -x ./patch-puppet-module -r tripleo:562542

upload-puppet-modules -d ~/puppet-modules --environment ${HOME}/puppet-patch.yaml
if ! grep puppet-patch.yaml overcloud-deploy.sh; then
    sed -i.before-patch -e 's,\$@,-e ${HOME}/puppet-patch.yaml $@,' overcloud-deploy.sh
fi

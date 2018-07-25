#!/usr/bin/bash

set -eux

echo "TO BE RUN BEFORE INIT STAGE."

# get a candidate for upgrade with selinux disabled.
ceph_ip=$(head -1 ~/ceph-ip.txt)
SSH="ssh -t"

echo "${ceph_ip} choosen"

${SSH} heat-admin@${ceph_ip} sudo sed -i.orig -e 's/SELINUX=permissive/SELINUX=disabled/' /etc/sysconfig/selinux
${SSH} heat-admin@${ceph_ip} sudo getenforce
${SSH} heat-admin@${ceph_ip} rpm -qa | grep ceph-selinux
${SSH} heat-admin@${ceph_ip} sudo reboot

max_wait=120
cur_wait=0
while ! ping -c 2 -W 1 ${ceph_ip}; do
    if [ $current_wait -ge $max_wait ]; then
        echo "Waited more than 2 minutes for the instance to come back, giving up."
        exit 1
    fi
    sleep 1
done

${SSH} heat-admin@${ceph_ip} sudo du -sh /var/lib/ceph/osd/ceph-1/
${SSH} heat-admin@${ceph_ip} sudo find /var/lib/ceph/osd/ceph-1/ -type f -ls

curl -v 'https://code.engineering.redhat.com/gerrit/changes/143420/revisions/latest/patch?download' \
    base64 -d | \
    sudo patch  -d /usr/share/openstack-tripleo-heat-templates/ -p1

echo "NOW RUN INIT."

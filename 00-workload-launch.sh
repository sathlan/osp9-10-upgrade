#!/usr/bin/bash
#
# Script that spawns an instance

set -exu

OVERCLOUD_RC=${HOME}/overcloudrc
IMAGE_URL="http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img"
IMAGE_NAME='upgrade_workload'
IMAGE_FILE=~/upgrade_workload.qcow2
KEYPAIR_NAME=userkey
FLAVOR_NAME='v1-1G-5G'
SECGROUP_NAME='allow-icmp-ssh'
TENANT_NET_NAME='internal_net'
EXTERNAL_NET_NAME='public'

source ${OVERCLOUD_RC}

openstack_version="$(openstack --version 2>&1)"
before_osp_10='false'
if [[ "$openstack_version" == *2.3.1 ]]; then
    before_osp_10='true'
fi

## create image

if ! openstack image list | grep ${IMAGE_NAME} ; then
    curl --silent -L -4 -o ${IMAGE_FILE} ${IMAGE_URL}
    openstack image create \
        --file ${IMAGE_FILE} \
        --disk-format qcow2 \
        --container-format bare \
        ${IMAGE_NAME}
fi

## create user key
if ! openstack keypair list | grep ${KEYPAIR_NAME}; then
    openstack keypair create --public-key ~/.ssh/id_rsa.pub ${KEYPAIR_NAME}
fi

## create flavor
if ! openstack flavor list | grep ${FLAVOR_NAME}; then
    openstack flavor create --vcpus 1 --ram 512 --disk 5 --swap 512 $FLAVOR_NAME
fi

## create networking
if ! openstack network list | grep ${TENANT_NET_NAME}; then
    NAMESERVER=$(grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /etc/resolv.conf  | head -1)
    openstack router create ${TENANT_NET_NAME}_router
    openstack network create ${TENANT_NET_NAME}
    # for osp9
    if [ $before_osp_10 = 'true' ]; then
        neutron subnet-create --allocation-pool start=192.168.0.10,end=192.168.0.100 \
                --gateway 192.168.0.254 \
                --dns-nameserver ${NAMESERVER} --name ${TENANT_NET_NAME}_subnet ${TENANT_NET_NAME} 192.168.0.0/24
        neutron router-interface-add ${TENANT_NET_NAME}_router ${TENANT_NET_NAME}_subnet
        neutron router-gateway-set ${TENANT_NET_NAME}_router public
    else
        openstack subnet create \
                  --subnet-range 192.168.0.0/24 \
                  --allocation-pool start=192.168.0.10,end=192.168.0.100 \
                  --gateway 192.168.0.254 \
                  --dns-nameserver ${NAMESERVER} \
                  --network ${TENANT_NET_NAME} \
                  ${TENANT_NET_NAME}_subnet
        openstack router add subnet  ${TENANT_NET_NAME}_router ${TENANT_NET_NAME}_subnet
        openstack router set --external-gateway ${EXTERNAL_NET_NAME} ${TENANT_NET_NAME}_router
    fi
fi

## create security group
if ! openstack security group list | grep ${SECGROUP_NAME}; then
    openstack security group create ${SECGROUP_NAME}
    openstack security group rule create --proto icmp ${SECGROUP_NAME}
    openstack security group rule create --proto tcp --dst-port 22 ${SECGROUP_NAME}
fi

## create instance
INSTANCE_NAME="instance_$(openssl rand -hex 5)"
TENANT_NET_ID=$(openstack network list -f json | jq -r -c ".[] | select(.Name | contains(\"$TENANT_NET_NAME\")) | .ID")
openstack server create  \
    --image ${IMAGE_NAME} \
    --flavor ${FLAVOR_NAME} \
    --security-group ${SECGROUP_NAME} \
    --key-name  ${KEYPAIR_NAME} \
    --nic net-id=${TENANT_NET_ID} \
    $INSTANCE_NAME

timeout_seconds=240
elapsed_seconds=0
while true; do
    if [ $before_osp_10 = 'true' ]; then
        INSTANCE_ACTIVE=$(openstack server show $INSTANCE_NAME| awk '/^\| status /{print $4}')
    else
        INSTANCE_ACTIVE=$(openstack server show $INSTANCE_NAME -f json | jq -r .status)
    fi
    if [ "$INSTANCE_ACTIVE" = 'ACTIVE' ]; then
        break
    fi
    sleep 3
    elapsed_seconds=$(expr $elapsed_seconds + 3)
    if [ $elapsed_seconds -ge $timeout_seconds ]; then
        echo "FAILURE: Instance failed to boot."
        exit 1
    fi
done

## assign floating ip
if [ $before_osp_10 = 'true' ]; then
    INSTANCE_FIP=$(neutron floatingip-create ${EXTERNAL_NET_NAME} | awk '/^\| id/{print $4}')
    INSTANCE_IP=$(openstack server show $INSTANCE_NAME | awk '/^\| addresses /{print $4}' | grep -oP '[0-9.]+')
    INSTANCE_PORT=$(neutron port-list | awk '/'$INSTANCE_IP'/{print $2}')
else
    INSTANCE_FIP=$(openstack floating ip create ${EXTERNAL_NET_NAME} -f json | jq -r .id)
    INSTANCE_IP=$(openstack server show $INSTANCE_NAME -f json  | jq -r .addresses | grep -oP '[0-9.]+')
    INSTANCE_PORT=$(openstack port list -f json | jq -r -c ".[] | select(.[\"Fixed IP Addresses\"] | contains(\"${INSTANCE_IP}\")) | .ID")
fi

neutron floatingip-associate ${INSTANCE_FIP} ${INSTANCE_PORT}

if [ $before_osp_10 != 'true' ]; then
    ## create and attach a volume
    CINDER_VOL_ID=$(openstack volume create --size 1 vol_$(openssl rand -hex 5) -f json | jq -r .id)
    openstack server add volume ${INSTANCE_NAME} ${CINDER_VOL_ID}
fi
if [ $before_osp_10 = 'true' ]; then
    FIP=$(neutron floatingip-show $INSTANCE_FIP  | awk '/^\| floating_ip_address/{print $4}')
else
    FIP=$(openstack floating ip show ${INSTANCE_FIP} -f json | jq -r .floating_ip_address)
fi
echo "floating-ip: $FIP" > ~/${INSTANCE_NAME}

echo fip=${FIP} > ~/instance.txt
echo instance=${INSTANCE_NAME} >> ~/instance.txt

ping -D ${FIP} >> ~/ping_results_$(date +%Y%m%d%H%M).log &

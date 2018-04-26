. overcloudrc
suffix="${1:?Please give a pre/post suffix}"
nova service-list > $suffix-info.log
neutron agent-list >> ${suffix}-info.log

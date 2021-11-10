#!/bin/bash


source function.sh
source config.sh


# Function edit /etc/nova/nova.conf file
nova_config () {
	echocolor "Edit /etc/nova/nova.conf file"
	sleep 3
	novafile=/etc/nova/nova.conf
	novafilebak=/etc/nova/nova.conf.bak
	test -f $novafilebak || cp $novafile $novafilebak

	crudini --set $novafile DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL_EXT_IP

	crudini --set $novafile api auth_strategy keystone

	crudini --set $novafile keystone_authtoken auth_url http://$CTL_EXT_IP:5000
	crudini --set $novafile keystone_authtoken memcached_servers $CTL_EXT_IP:11211
	crudini --set $novafile keystone_authtoken auth_type password
	crudini --set $novafile keystone_authtoken project_domain_name default
	crudini --set $novafile keystone_authtoken user_domain_name default
	crudini --set $novafile keystone_authtoken project_name service
	crudini --set $novafile keystone_authtoken username nova
	crudini --set $novafile keystone_authtoken password $NOVA_PASS

	crudini --set $novafile DEFAULT my_ip $COM1_MGNT_IP

	crudini --set $novafile DEFAULT use_neutron True

	crudini --set $novafile DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

	crudini --set $novafile vnc enabled True
	crudini --set $novafile vnc server_listen 0.0.0.0
	crudini --set $novafile vnc server_proxyclient_address \$my_ip
	crudini --set $novafile vnc novncproxy_base_url http://$CTL_EXT_IP:6080/vnc_auto.html

	crudini --set $novafile glance api_servers http://$CTL_EXT_IP:9292

	crudini --set $novafile oslo_concurrency lock_path /var/lib/nova/tmp
		
	crudini -del $novafile DEFAULT log_dir

	crudini -del $novafile placement os_region_name
	crudini --set $novafile placement os_region_name RegionOne
	crudini --set $novafile placement project_domain_name Default
	crudini --set $novafile placement project_name service
	crudini --set $novafile placement auth_type password
	crudini --set $novafile placement user_domain_name Default
	crudini --set $novafile placement auth_url http://$CTL_EXT_IP:5000/v3
	crudini --set $novafile placement username placement
	crudini --set $novafile placement password $PLACEMENT_PASS
	
	novacomputefile=/etc/nova/nova-compute.conf
	novacomputefilebak=/etc/nova/nova-compute.conf.bak
	test -f $novacomputefilebak || cp $novacomputefile $novacomputefilebak

	crudini --set $novacomputefile libvirt virt_type qemu
}

# Function finalize installation
nova_restart () {
	echocolor "Finalize installation"
	sleep 3
	service nova-compute restart
}

#######################
###Execute functions###
#######################


# Edit /etc/nova/nova.conf file
nova_config

# Finalize installation
nova_restart
#!/bin/bash
# Author DucElGenio

source function.sh
source config.sh

# Function create database for Neutron
neutron_create_db () {
	echocolor "Create database for Neutron"
	sleep 3

	cat << EOF | mysql
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';
EOF
}

# Function create the neutron service credentials
neutron_create_info () {

	echocolor "Create the neutron service credentials"
	sleep 3

	openstack user create --domain default --password $NEUTRON_PASS neutron
	openstack role add --project service --user neutron admin
	openstack service create --name neutron --description "OpenStack Networking" network
	openstack endpoint create --region RegionOne network public http://$HOST_CTL:9696
	openstack endpoint create --region RegionOne network internal http://$HOST_CTL:9696
	openstack endpoint create --region RegionOne network admin http://$HOST_CTL:9696
}

# Function install the components
neutron_install () {
	echocolor "Install the components"
	sleep 3
	apt -y install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent python3-neutronclient
}

# Function configure the server component
neutron_config_server_component () { 
	echocolor "Configure the server component"
	sleep 3
	neutronfile=/etc/neutron/neutron.conf
	neutronfilebak=/etc/neutron/neutron.conf.bak
	cp $neutronfile $neutronfilebak
	egrep -v "^$|^#" $neutronfilebak > $neutronfile

	crudini --set $neutronfile database connection mysql+pymysql://neutron:$NEUTRON_DBPASS@$HOST_CTL/neutron

	crudini --set $neutronfile DEFAULT core_plugin ml2
	crudini --set $neutronfile DEFAULT service_plugins router
	crudini --set $neutronfile DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$HOST_CTL
	crudini --set $neutronfile DEFAULT auth_strategy keystone
	crudini --set $neutronfile keystone_authtoken auth_uri http://$HOST_CTL:5000
	crudini --set $neutronfile keystone_authtoken auth_url http://$HOST_CTL:5000
	crudini --set $neutronfile keystone_authtoken memcached_servers $HOST_CTL:11211
	crudini --set $neutronfile keystone_authtoken auth_type password
	crudini --set $neutronfile keystone_authtoken project_domain_name default
	crudini --set $neutronfile keystone_authtoken user_domain_name default
	crudini --set $neutronfile keystone_authtoken project_name service
	crudini --set $neutronfile keystone_authtoken username neutron
	crudini --set $neutronfile keystone_authtoken password $NEUTRON_PASS

	crudini --set $neutronfile DEFAULT notify_nova_on_port_status_changes true
	crudini --set $neutronfile DEFAULT notify_nova_on_port_data_changes true
	crudini --set $neutronfile nova auth_url http://$HOST_CTL:5000
	crudini --set $neutronfile nova auth_type password
	crudini --set $neutronfile nova project_domain_name default
	crudini --set $neutronfile nova user_domain_name default
	crudini --set $neutronfile nova region_name RegionOne
	crudini --set $neutronfile nova project_name service
	crudini --set $neutronfile nova username nova
	crudini --set $neutronfile nova password $NOVA_PASS
}

# Function configure the Modular Layer 2 (ML2) plug-in
neutron_config_ml2 () {
	echocolor "Configure the Modular Layer 2 (ML2) plug-in"
	sleep 3
	ml2file=/etc/neutron/plugins/ml2/ml2_conf.ini
	ml2filebak=/etc/neutron/plugins/ml2/ml2_conf.ini.bak
	cp $ml2file $ml2filebak
	egrep -v "^$|^#" $ml2filebak > $ml2file

	crudini --set $ml2file ml2 type_drivers flat,vlan
	crudini --set $ml2file ml2 tenant_network_types
	crudini --set $ml2file ml2 mechanism_drivers linuxbridge
	crudini --set $ml2file ml2 extension_drivers port_security
}

# Function configure the Linux bridge agent
neutron_config_lb () {
	echocolor "Configure the Linux bridge agent"
	sleep 3
	lbfile=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
	lbfilebak=/etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
	cp $lbfile $ovsfilebak
	egrep -v "^$|^#" $lbfilebak > $lbfile

	crudini --set $lbfile securitygroup enable_security_group True
	crudini --set $lbfile securitygroup firewall_driver iptables
    crudini --set $lbfile securitygroup enable_ipset True
	
}

# Function configure the DHCP agent
neutron_config_dhcp () {
	echocolor "Configure the DHCP agent"
	sleep 3
	dhcpfile=/etc/neutron/dhcp_agent.ini
	dhcpfilebak=/etc/neutron/dhcp_agent.ini.bak
	cp $dhcpfile $dhcpfilebak
	egrep -v "^$|^#" $dhcpfilebak > $dhcpfile

	crudini --set $dhcpfile DEFAULT interface_driver linuxbridge
	crudini --set $dhcpfile DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
	crudini --set $dhcpfile DEFAULT enable_isolated_metadata True
}

# Function configure L3 agent
neutron_config_l3 () {
    echocolor "Configure the L3 agent"
    sleep 3
    l3file=/etc/neutron/l3_agent.ini
	l3filebak=/etc/neutron/l3_agent.ini.bak
	cp $l3file $l3filebak
	egrep -v "^$|^#" $l3filebak > $l3file

	crudini --set $l3file DEFAULT interface_driver linuxbridge
}

# Function configure things relation
neutron_config_relation () {
	cat << EOF > /etc/network/interfaces
# loopback network interface
auto lo
iface lo inet loopback
external network interface
# auto $CTL_EXT_IF
# iface $CTL_EXT_IF inet static
# address $CTL_EXT_IP
# netmask $CTL_EXT_NETMASK
# gateway $GATEWAY_EXT_IP
#dns-nameservers 8.8.8.8
LinkLocalAddressing=no
IPv6AcceptRA=no

EOF
}

# Function configure the metadata agent
neutron_config_metadata () {
	echocolor "Configure the metadata agent"
	sleep 3
	metadatafile=/etc/neutron/metadata_agent.ini
	metadatafilebak=/etc/neutron/metadata_agent.ini.bak
	cp $metadatafile $metadatafilebak
	egrep -v "^$|^#" $metadatafilebak > $metadatafile

	crudini --set $metadatafile DEFAULT nova_metadata_host $HOST_CTL
	crudini --set $metadatafile DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
    crudini --set $metadatafile DEFAULT memcache_servers $HOST_CTL:11211
}


# Function configure the Compute service to use the Networking service
neutron_config_compute_use_network () {
	echocolor "Configure the Compute service to use the Networking service"
	sleep 3
	novafile=/etc/nova/nova.conf

	crudini --set $novafile neutron url http://$HOST_CTL:9696
	crudini --set $novafile neutron auth_url http://$HOST_CTL:5000
	crudini --set $novafile neutron auth_type password
	crudini --set $novafile neutron project_domain_name default
	crudini --set $novafile neutron user_domain_name default
	crudini --set $novafile neutron region_name RegionOne
	crudini --set $novafile neutron project_name service
	crudini --set $novafile neutron username neutron
	crudini --set $novafile neutron password $NEUTRON_PASS
	crudini --set $novafile neutron service_metadata_proxy true
	crudini --set $novafile neutron metadata_proxy_shared_secret $METADATA_SECRET
}

# Function populate the database
neutron_populate_db () {
	echocolor "Populate the database"
	sleep 3
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
	  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
}

# Function restart installation
neutron_restart () {
	service nova-api restart
	service neutron-server restart
	service neutron-openvswitch-agent restart
	service neutron-dhcp-agent restart
	service neutron-metadata-agent restart
}

#######################
###Execute functions###
#######################

# Create database for Neutron
neutron_create_db

# Create the neutron service credentials
neutron_create_info

# Install the components
neutron_install

# Configure the server component
neutron_config_server_component

# Configure the Modular Layer 2 (ML2) plug-in
neutron_config_ml2

# Configure the Open vSwitch agent
neutron_config_ovs

# Configure the DHCP agent
neutron_config_dhcp

# Configure things relation
neutron_config_relation

# Configure the metadata agent
neutron_config_metadata

# Configure the Compute service to use the Networking service
neutron_config_compute_use_network

# Populate the database
neutron_populate_db

# Function restart installation
neutron_restart
#!/bin/bash
#Author Nguyen Trong Tan

source function.sh
source config.sh

# Function install the components Neutron
neutron_install () {
	echocolor "Install the components Neutron"
	sleep 3

	apt install neutron-openvswitch-agent -y
}

# Function configure the common component
neutron_config_server_component () {
	echocolor "Configure the common component"
	sleep 3

	neutronfile=/etc/neutron/neutron.conf
	neutronfilebak=/etc/neutron/neutron.conf.bak
	cp $neutronfile $neutronfilebak
	egrep -v "^$|^#" $neutronfilebak > $neutronfile

	crudini --del $neutronfile database connection
	crudini --set $neutronfile DEFAULT \
		transport_url rabbit://openstack:$RABBIT_PASS@$HOST_CTL

	crudini --set $neutronfile DEFAULT auth_strategy keystone
	crudini --set $neutronfile keystone_authtoken \
		auth_uri http://$HOST_CTL:5000
	crudini --set $neutronfile keystone_authtoken \
		auth_url http://$HOST_CTL:5000
	crudini --set $neutronfile keystone_authtoken \
		memcached_servers $HOST_CTL:11211
	crudini --set $neutronfile keystone_authtoken \
		auth_type password
	crudini --set $neutronfile keystone_authtoken \
		project_domain_name default
	crudini --set $neutronfile keystone_authtoken \
		user_domain_name default
	crudini --set $neutronfile keystone_authtoken \
		project_name service
	crudini --set $neutronfile keystone_authtoken \
		username neutron
	crudini --set $neutronfile keystone_authtoken \
		password $NEUTRON_PASS
}

# Function configure the Open vSwitch agent
neutron_config_ovs () {
	echocolor "Configure the Open vSwitch agent"
	sleep 3
	ovsfile=/etc/neutron/plugins/ml2/openvswitch_agent.ini
	ovsfilebak=/etc/neutron/plugins/ml2/openvswitch_agent.ini.bak
	cp $ovsfile $ovsfilebak
	egrep -v "^$|^#" $ovsfilebak > $ovsfile

	crudini --set $ovsfile ovs bridge_mappings provider:br-provider
	crudini --set $ovsfile securitygroup firewall_driver iptables_hybrid
}

# Function configure things relation
neutron_config_relation () {
	ovs-vsctl add-br br-provider
	ovs-vsctl add-port br-provider $COM1_EXT_IF
	ip a flush $COM1_EXT_IF
	ifconfig br-provider $COM1_EXT_IP netmask $COM1_EXT_NETMASK
	ip link set br-provider up
	ip r add default via $GATEWAY_EXT_IP
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	
	cat << EOF > /etc/network/interfaces
# loopback network interface
auto lo
iface lo inet loopback
auto br-provider
allow-ovs br-provider
iface br-provider inet static
    address $COM1_EXT_IP
    netmask $COM1_EXT_NETMASK
    gateway $GATEWAY_EXT_IP
    dns-nameservers 8.8.8.8 8.8.4.4
    ovs_type OVSBridge
    ovs_ports $COM1_EXT_IF
allow-br-provider $COM1_EXT_IF
iface $COM1_EXT_IF inet manual
    ovs_bridge br-provider
    ovs_type OVSPort
# internal network interface
auto $COM1_MGNT_IF
iface $COM1_MGNT_IF inet static
address $COM1_MGNT_IP
netmask $COM1_MGNT_NETMASK
EOF
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

# Function restart installation
neutron_restart () {
	echocolor "Finalize installation"
	sleep 3
	service nova-compute restart
	service neutron-openvswitch-agent restart
}

#######################
###Execute functions###
#######################

# Install the components Neutron
neutron_install

# Configure the common component
neutron_config_server_component

# Configure the Open vSwitch agent
neutron_config_ovs

# Configure things relation
neutron_config_relation
	
# Configure the Compute service to use the Networking service
neutron_config_compute_use_network
	
# Restart installation
neutron_restart
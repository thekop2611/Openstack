#!/bin/bash
#Author DucElGenio

source config.sh

horizon_network_model=$1

# Function install the packages
horizon_install () {
	echocolor "Install the packages"
	sleep 3
	apt install openstack-dashboard -y
}


# Function edit the /etc/openstack-dashboard/local_settings.py file
horizon_config () {
	echocolor "Edit the /etc/openstack-dashboard/local_settings.py file"
	sleep 3

	horizonfile=/etc/openstack-dashboard/local_settings.py
	horizonfilebak=/etc/openstack-dashboard/local_settings.py.bak
	test -f $horizonfilebak || cp $horizonfile $horizonfilebak

	sed -i 's/OPENSTACK_HOST = "127.0.0.1"/'"OPENSTACK_HOST = \"$CTL_EXT_IP\""'/g' $horizonfile

	echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" >> $horizonfile
	sed -i "s/'LOCATION': '127.0.0.1:11211',/""'LOCATION': '$CTL_EXT_IP:11211',""/g" $horizonfile
	sed -i 's/OPENSTACK_KEYSTONE_URL = "http:\/\/%s:5000\/v2.0" % OPENSTACK_HOST/OPENSTACK_KEYSTONE_URL = "http:\/\/%s:5000\/v3" % OPENSTACK_HOST/g' $horizonfile

	echo "OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True" >> $horizonfile
	sed -i 's/TIME_ZONE = "UTC"/TIME_ZONE = "Asia\/Ho_Chi_Minh"/g' $horizonfile
    echo "OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'" >> $horizonfile
}

# Function restart installation
horizon_restart () {
	echocolor "Restart installation"
	sleep 3
	service apache2 reload
}

#######################
###Execute functions###
#######################

# Install the packages
horizon_install

# Edit the /etc/openstack-dashboard/local_settings.py file
horizon_config

# Restart installation
horizon_restart

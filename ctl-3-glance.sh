#!/bin/bash
#Author DucElGenio

source function.sh
source config.sh

# Function create database for Glance
glance_create_db () {
	echocolor "Create database for Glance"
	sleep 3

	cat << EOF | mysql
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';
FLUSH PRIVILEGES;
EOF
}

# Function create the Glance service credentials
glance_create_service () {
	
	echocolor "Create the service credentials"
	sleep 3

	openstack user create --domain default --password $GLANCE_PASS glance
	openstack role add --project service --user glance admin
	openstack service create --name glance --description "OpenStack Image" image
	openstack endpoint create --region RegionOne image public http://$CTL_EXT_IP:9292
	openstack endpoint create --region RegionOne image internal http://$CTL_EXT_IP:9292
	openstack endpoint create --region RegionOne image admin http://$CTL_EXT_IP:9292
}

# Function install components of Glance
glance_install () {
	echocolor "Install and configure components of Glance"
	sleep 3

	apt-get install glance -y
}

# Function config /etc/glance/glance-api.conf file
glance_config_api () {
	glanceapifile=/etc/glance/glance-api.conf
	glanceapifilebak=/etc/glance/glance-api.conf.bak
	test -f $glanceapifilebak || cp $glanceapifile $glanceapifilebak

	crudini --set $glanceapifile database connection mysql+pymysql://glance:$GLANCE_DBPASS@$CTL_EXT_IP/glance
	crudini --set $glanceapifile keystone_authtoken auth_url http://$CTL_EXT_IP:5000
    crudini --set $glanceapifile keystone_authtoken www_authenticate_uri http://$CTL_EXT_IP:5000
	crudini --set $glanceapifile keystone_authtoken memcached_servers $CTL_EXT_IP:11211	  
	crudini --set $glanceapifile keystone_authtoken auth_type password	  
	crudini --set $glanceapifile keystone_authtoken project_domain_name default
	crudini --set $glanceapifile keystone_authtoken user_domain_name default
	crudini --set $glanceapifile keystone_authtoken project_name service		
	crudini --set $glanceapifile keystone_authtoken username glance
	crudini --set $glanceapifile keystone_authtoken password $GLANCE_PASS
	crudini --set $glanceapifile paste_deploy flavor keystone	
	crudini --set $glanceapifile glance_store stores file,http		
	crudini --set $glanceapifile glance_store default_store file		
	crudini --set $glanceapifile glance_store filesystem_store_datadir /var/lib/glance/images/
}


# Function populate the Image service database
glance_populate_db () {
	echocolor "Populate the Image service database"
	sleep 3
    chmod 640 /etc/glance/glance-api.conf
    chown root:glance /etc/glance/glance-api.conf
	su -s /bin/bash glance -c "glance-manage db_sync"
}


# Function restart the Image services
glance_restart () {
	echocolor "Restart the Image services"
	sleep 3

	service glance-api restart 
    systemctl enable glance-api
}

# Function upload image to Glance
glance_upload_image () {
	echocolor "Upload image to Glance"
	sleep 3
	apt-get install wget -y
	wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img

	openstack image create "cirros" \
	  --file cirros-0.3.5-x86_64-disk.img \
	  --disk-format qcow2 --container-format bare \
	  --public
	  
	openstack image list
}

#######################
###Execute functions###
#######################

# Create database for Glance
glance_create_db

# Create the Glance service credentials
glance_create_service

# Install components of Glance
glance_install

# Config /etc/glance/glance-api.conf file
glance_config_api

# Populate the Image service database 
glance_populate_db

# Restart the Image services
glance_restart 
  
# Upload image to Glance
glance_upload_image
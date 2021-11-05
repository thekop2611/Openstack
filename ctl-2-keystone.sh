#!/bin/bash
# Author DucElGenio

source function.sh
source config.sh

# Function create database for Keystone
keystone_create_db () {
	echocolor "Create database for Keystone"
	sleep 3

	cat << EOF | mysql
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
flush privileges; 
EOF
}

# Function install components of Keystone
keystone_install () {
	echocolor "Install and configure components of Keystone"
	sleep 3
	apt -y install keystone python3-openstackclient apache2 libapache2-mod-wsgi-py3 python3-oauth2client
}

# Function configure components of Keystone
keystone_config () {
	keystonefile=/etc/keystone/keystone.conf
	keystonefilebak=/etc/keystone/keystone.conf.bak
	test -f $keystonefilebak || cp $keystonefile $keystonefilebak

	ops_add $keystonefile connection mysql+pymysql://keystone:$KEYSTONE_DBPASS@$CTL_EXT_IP/keystone
	ops_add $keystonefile provider = fernet
    ops_add $keystonefile memcache_servers = $CTL_EXT_IP:11211
}

# Function populate the Identity service database
keystone_populate_db () {
	su -s /bin/bash keystone -c "keystone-manage db_sync"
}

# Function initialize Fernet key repositories
keystone_initialize_key () {
	keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
	keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
}
	
# Function bootstrap the Identity service
keystone_bootstrap () {
	keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
	  --bootstrap-admin-url http://$CTL_EXT_IP:5000/v3/ \
	  --bootstrap-internal-url http://$CTL_EXT_IP:5000/v3/ \
	  --bootstrap-public-url http://$CTL_EXT_IP:5000/v3/ \
	  --bootstrap-region-id RegionOne
}
	
# Function configure the Apache HTTP server
keystone_config_apache () {
	echocolor "Configure the Apache HTTP server"
	sleep 3
	echo "ServerName $CTL_EXT_IP" >> /etc/apache2/apache2.conf
}

# Function finalize the installation
keystone_finalize_install () {
	echocolor "Finalize the installation"
	sleep 3
	systemctl restart apache2
}

# Function create domain, projects, users and roles
keystone_create_domain_project_user_role () {
	export OS_PROJECT_DOMAIN_NAME=default
    export OS_USER_DOMAIN_NAME=default
    export OS_PROJECT_NAME=admin
    export OS_USERNAME=admin
    export OS_PASSWORD=$ADMIN_PASS
    export OS_AUTH_URL=http://$CTL_EXT_IP:5000/v3
    export OS_IDENTITY_API_VERSION=3
    export OS_IMAGE_API_VERSION=2
    export PS1='\u@\h \W(keystone)\$ '

    chmod 600 ~/keystonerc
    source ~/keystonerc
    echo "source ~/keystonerc " >> ~/.bashrc
	
	echocolor "Create domain, projects, users and roles"
	sleep 3

	openstack project create --domain default --description "Service Project" service	  
	openstack project create --domain default --description "Demo Project" demo
	openstack user create --domain default --password $DEMO_PASS demo
	openstack role create user
	openstack role add --project demo --user demo user
}



# Function verifying keystone
keystone_verify () {
	echocolor "Verifying keystone"
	sleep 3
	openstack token issue
}

#######################
###Execute functions###
#######################

# Create database for Keystone
keystone_create_db

# Install components of Keystone
keystone_install

# Configure components of Keystone
keystone_config

# Populate the Identity service database
keystone_populate_db

# Initialize Fernet key repositories
keystone_initialize_key

# Bootstrap the Identity service
keystone_bootstrap

# Configure the Apache HTTP server
keystone_config_apache

# Finalize the installation
keystone_finalize_install

# Create domain, projects, users and roles
keystone_create_domain_project_user_role


# Verifying keystone
keystone_verify
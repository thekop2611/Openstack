#!/bin/bash
#Author DucElGenio

source config.sh

# Function update and upgrade for CONTROLLER
update_upgrade () {
	echocolor "Update and Update controller"
	sleep 3
	apt update -y && apt upgrade -y
}

# Function install crudini
install_crudini () {
	echocolor "Install crudini"
	sleep 3
	apt install -y crudini
}

# Function install and config NTP
install_ntp () {
	echocolor "Install NTP"
	sleep 3

	apt install chrony -y
	ntpfile=/etc/chrony/chrony.conf

	sed -i 's/pool ntp.ubuntu.com        iburst maxsources 4/ \
pool 2.debian.pool.ntp.org offline iburst/g' $ntpfile

	sed -i 's/pool 0.ubuntu.pool.ntp.org iburst maxsources 1/ \
server 0.asia.pool.ntp.org iburst/g' $ntpfile

	sed -i 's/pool 1.ubuntu.pool.ntp.org iburst maxsources 1/ \
server 1.asia.pool.ntp.org iburst/g' $ntpfile

	sed -i 's/pool 2.ubuntu.pool.ntp.org iburst maxsources 2//g' $ntpfile

	echo "allow $CIDR_MGNT" >> $ntpfile

	timedatectl set-timezone Asia/Ho_Chi_Minh

	service chrony restart
}

# Function install OpenStack packages (python-openstackclient)
install_ops_packages () {
	echocolor "Install OpenStack client"
	sleep 3
	apt -y install software-properties-common
	add-apt-repository cloud-archive:xena
	apt update -y && apt -y upgrade
    apt -y install libgtk-3-dev
}

# Function install mysql
install_sql () {
	echocolor "Install SQL database - Mariadb"
	sleep 3

	apt install mariadb-server python3-pymysql  -y

	sqlfile=/etc/mysql/mariadb.conf.d/50-server.cnf
	touch $sqlfile
	cat << EOF >$sqlfile
[mysqld]
bind-address = 0.0.0.0
max_connections = 500
collation-server = utf8mb4_general_ci
character-set-server = utf8mb4
EOF

    systemctl restart mariadb
    mysql_secure_installation



}

# Function install message queue
install_mq () {
	echocolor "Install Message queue (rabbitmq)"
	sleep 3

	apt -y install rabbitmq-server
	rabbitmqctl add_user openstack $RABBIT_PASS
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
}

# Function install Memcached
install_memcached () {
	echocolor "Install Memcached"
	sleep 3

	apt install memcached python-memcache -y
	memcachefile=/etc/memcached.conf
	sed -i 's|-l 127.0.0.1|'"-l 0.0.0.0"'|g' $memcachefile

	systemctl restart memcached
} 

#######################
###Execute functions###
#######################

# Update and upgrade for controller
update_upgrade

# Install crudini
install_crudini

# Install and config NTP
install_ntp

# OpenStack packages (python-openstackclient)
install_ops_packages

# Install SQL database (Mariadb)
install_sql

# Install Message queue (rabbitmq)
install_mq

# Install Memcached
install_memcached

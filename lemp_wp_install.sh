#!/bin/bash -e
dir="/var/www/html"
dbname="wordpress"
dbuser="root"
dbpass="sshs"

clear
echo "============================================"
echo "WordPress Install Script"
echo "============================================"
echo "run install? (y/n)"
read -e run
if [ "$run" == n ] ; then
	exit
else
	echo "============================================"
	echo "A robot is now installing WordPress for you."
	echo "============================================"


	echo "run set Peril locales? (y/n)"
	read -e runPeril
	if [ "$runPeril" == y ] ; then
		#handles perl error
		sudo locale-gen en_US en_US.UTF-8 hu_HU hu_HU.UTF-8
		sudo dpkg-reconfigure locales

	fi

	#Set up lamp server
	echo "============================================"
	echo "Installing LAMP Server"
	echo "============================================"
	sudo apt-get update
	sudo apt-get install apache2 -y
	sudo apt-get install php5 libapache2-mod-php5 -y
	sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password sshs'
	sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password sshs'
	sudo apt-get -y install mysql-server
	sudo apt-get install php5-mysql -y
	#need to set root password


	echo "Do you need to setup new MySQL database? (y/n)"
	read -e setupmysql
	if [ "$setupmysql" == y ] ; then

		echo "============================================"
		echo "Setting up the database."
		echo "============================================"
		#login to MySQL, add database

		mysql -u root -psshs << EOF
			create database wordpress;
EOF
#EOF CAN'T BE NESTED
	fi


	#Download and setup wordpress
	echo "============================================"
	echo "Installing WordPress for you."
	echo "============================================"
	# wget /var/www/html/latest.tar.gz https://wordpress.org/latest.tar.gz
	sudo wget -O- https://wordpress.org/latest.tar.gz >/var/www/html/latest.tar.gz
	sudo tar vxf /var/www/html/latest.tar.gz
	sudo mv /var/www/html/wordpress/* /var/www/html
	sudo rm -rf /var/www/html/wordpress latest.tar.gz

	sudo /etc/init.d/apache2 reload
	# sudo /etc/init.d/apache2 restart
	

	#create wp config
	sudo cp wp-config-sample.php wp-config.php

	#set database details with perl find and replace
	sudo perl -pi.back -e "s/database_name_here/$dbname/g;" wp-config.php
	sudo perl -pi -e "s/username_here/$dbuser/g" wp-config.php
	sudo perl -pi -e "s/password_here/$dbpass/g" wp-config.php

	#create uploads folder and set permissions
	sudo mkdir /var/www/html/wp-content/uploads
	sudo chmod 775 /var/www/html/wp-content/uploads
	sudo chown -R pi: /var/www/html


	echo "========================="
	echo "Installation is complete."
	echo "========================="
fi

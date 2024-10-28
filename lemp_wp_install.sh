#!/bin/bash -e

# Default configuration
dir="/var/www/html"
dbname="wordpress"
default_user="wpuser"
default_pass="wppass123"
default_domain="example.com"

# Function to check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Function to prompt for confirmation
confirm_step() {
    local message=$1
    echo "============================================"
    echo "$message"
    echo "Proceed with this step? (y/n)"
    read -e confirm
    if [ "$confirm" != "y" ]; then
        echo "Skipping this step..."
        return 1
    fi
    return 0
}

# Function to create nginx server block
create_nginx_config() {
    local domain=$1
    local config_file="/etc/nginx/sites-available/$domain"
    
    echo "Creating NGINX configuration for $domain..."
    
    # Create nginx config file
    sudo tee $config_file > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    
    root /var/www/html;
    index index.php index.html index.htm;
    
    server_name $domain www.$domain;
    
    client_max_body_size 64M;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
    
    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt { log_not_found off; access_log off; allow all; }
    
    location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
        expires max;
        log_not_found off;
    }
}
EOF

    # Create symbolic link
    sudo ln -sf $config_file /etc/nginx/sites-enabled/
    
    # Remove default nginx site if it exists
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test nginx configuration
    sudo nginx -t
    
    # Reload nginx
    sudo systemctl reload nginx
}

clear
echo "============================================"
echo "WordPress LEMP Install Script"
echo "============================================"

if ! confirm_step "Start WordPress LEMP installation?"; then
    exit 1
fi

# Prompt for domain
read -p "Enter your domain (default: $default_domain): " domain_name
domain_name=${domain_name:-$default_domain}

# Prompt for database credentials
read -p "Enter database user (default: $default_user): " dbuser
dbuser=${dbuser:-$default_user}

read -p "Enter database password (default: $default_pass): " dbpass
dbpass=${dbpass:-$default_pass}

echo "============================================"
echo "Installation will use the following settings:"
echo "Domain: $domain_name"
echo "Database User: $dbuser"
echo "Database Name: $dbname"
echo "============================================"

if confirm_step "Configure system locales?"; then
    sudo locale-gen en_US en_US.UTF-8 de_DE de_DE.UTF-8
    sudo dpkg-reconfigure locales
fi

if confirm_step "Update system packages?"; then
    sudo apt-get update
fi

# NGINX Installation
if ! is_installed nginx; then
    if confirm_step "NGINX is not installed. Install NGINX?"; then
        sudo apt install nginx -y
    else
        echo "NGINX is required for this installation. Exiting."
        exit 1
    fi
else
    echo "NGINX is already installed."
fi

# PHP Installation
if confirm_step "Install PHP and required modules?"; then
    sudo apt install php php-fpm php-mysql -y
fi

# MariaDB Installation
if confirm_step "Install MariaDB (MySQL)?"; then
    sudo apt install mariadb-server mariadb-client -y
fi

# Database Configuration
if confirm_step "Configure MySQL user and permissions?"; then
    mysql -u root -e "CREATE USER IF NOT EXISTS '$dbuser'@'%' IDENTIFIED BY '$dbpass'; 
                     GRANT ALL PRIVILEGES ON *.* TO '$dbuser'@'%';
                     FLUSH PRIVILEGES;"
fi

if confirm_step "Create WordPress database?"; then
    echo "Creating database: $dbname"
    mysql -u root << EOF
create database if not exists wordpress;
EOF
fi

# WordPress Download and Setup
if confirm_step "Download and extract WordPress?"; then
    echo "Creating website directory..."
    sudo mkdir -p /var/www/html
    
    echo "Downloading WordPress..."
    sudo wget -O- https://wordpress.org/latest.tar.gz > /var/www/html/latest.tar.gz
    
    echo "Extracting WordPress..."
    sudo tar xf /var/www/html/latest.tar.gz -C /var/www/html
    sudo mv /var/www/html/wordpress/* /var/www/html/
    sudo rm -rf /var/www/html/wordpress /var/www/html/latest.tar.gz
fi

# Domain Configuration
if confirm_step "Configure NGINX for domain $domain_name?"; then
    create_nginx_config $domain_name
fi

# WordPress Configuration
if confirm_step "Configure WordPress?"; then
    cd /var/www/html
    sudo cp wp-config-sample.php wp-config.php
    
    # Set database details with perl find and replace
    sudo perl -pi.back -e "s/database_name_here/$dbname/g;" wp-config.php
    sudo perl -pi -e "s/username_here/$dbuser/g" wp-config.php
    sudo perl -pi -e "s/password_here/$dbpass/g" wp-config.php
fi

# Permissions Setup
if confirm_step "Set up WordPress permissions?"; then
    sudo mkdir -p /var/www/html/wp-content/uploads
    sudo chmod 775 /var/www/html/wp-content/uploads
    sudo chown -R www-data:www-data /var/www/html
fi

echo "============================================"
echo "WordPress installation is complete!"
echo "Domain: http://$domain_name"
echo ""
echo "Next steps:"
echo "1. Update your DNS records to point to this server"
echo "2. Consider installing SSL certificate using Let's Encrypt"
echo "3. Complete WordPress installation through web interface"
echo "============================================"
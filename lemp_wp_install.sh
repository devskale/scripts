#!/bin/bash -e

# Default configuration
dir="/var/www/html"
dbname="wordpress"
default_user="wpuser"
default_pass="wppass123"
default_domain="example.com"
php_version=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "8.1")

# Function to check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Function to generate secure password
generate_secure_password() {
    openssl rand -base64 16 | tr -d '/+='
}

# Function to validate domain name
validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid domain name format. Please try again."
        return 1
    fi
    return 0
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

# Function to create nginx server block with enhanced security
create_nginx_config() {
    local domain=$1
    local config_file="/etc/nginx/sites-available/$domain"
    
    echo "Creating NGINX configuration for $domain..."
    
    # Create nginx config file with security headers and SSL configuration
    sudo tee $config_file > /dev/null <<EOF
# HTTP redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    # Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response.
    return 301 https://\$server_name\$request_uri;
}

# Main server block for HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    root /var/www/html;
    index index.php index.html index.htm;
    
    server_name $domain www.$domain;
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # Modern configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # HSTS (uncomment after you're sure everything works)
    # add_header Strict-Transport-Security "max-age=63072000" always;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # Increase body size limit for larger uploads
    client_max_body_size 64M;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: ws: wss: data: blob: 'unsafe-inline' 'unsafe-eval';" always;
    
    # WordPress permalinks and uploads
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP handling with security measures
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_intercept_errors on;
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_param PHP_VALUE "upload_max_filesize=64M \n post_max_size=64M";
        
        # FastCGI HTTPS parameters
        fastcgi_param HTTPS on;
        fastcgi_param HTTP_SCHEME https;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to sensitive WordPress files
    location ~* /(?:wp-config.php|readme.html|license.txt|xmlrpc.php) {
        deny all;
    }
    
    # Static content handling with improved caching
    location ~* \.(css|gif|ico|jpeg|jpg|js|png|webp|svg|woff|woff2|ttf|eot)$ {
        expires max;
        log_not_found off;
        access_log off;
        add_header Cache-Control "public, no-transform";
        add_header X-Content-Type-Options "nosniff";
    }
    
    # Disable WordPress admin-ajax.php logging
    location /wp-admin/admin-ajax.php {
        access_log off;
    }
}
EOF

    # Create symbolic link
    sudo ln -sf $config_file /etc/nginx/sites-enabled/
    
    # Remove default nginx site if it exists
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test nginx configuration
    if ! sudo nginx -t; then
        echo "NGINX configuration test failed. Please check the configuration."
        exit 1
    fi
    
    # Reload nginx
    sudo systemctl reload nginx
}

# Function to secure WordPress installation
secure_wordpress() {
    local wp_config="/var/www/html/wp-config.php"
    
    # Generate WordPress salts
    echo "Generating secure WordPress salts..."
    local salts=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    
    # Add salts to wp-config.php
    sudo sed -i "/define( *'AUTH_KEY'/,/define( *'NONCE_SALT'/d" $wp_config
    echo "$salts" | sudo tee -a $wp_config > /dev/null
    
    # Add security configurations
    sudo tee -a $wp_config > /dev/null <<EOF

/* Security configurations */
define('DISALLOW_FILE_EDIT', true);
define('WP_AUTO_UPDATE_CORE', 'minor');
define('WP_POST_REVISIONS', 5);
define('FORCE_SSL_ADMIN', true);
define('WP_MEMORY_LIMIT', '256M');
EOF
}

clear
echo "============================================"
echo "WordPress LEMP Install Script"
echo "============================================"

if ! confirm_step "Start WordPress LEMP installation?"; then
    exit 1
fi

# System checks
if [[ $EUID -ne 0 ]] && ! sudo -v; then
    echo "This script requires sudo privileges. Please run with sudo or as root."
    exit 1
fi

# Prompt for domain with validation
while true; do
    read -p "Enter your domain (default: $default_domain): " domain_name
    domain_name=${domain_name:-$default_domain}
    if validate_domain "$domain_name"; then
        break
    fi
done

# Generate secure database credentials if not provided
dbpass=${dbpass:-$(generate_secure_password)}
dbuser=${dbuser:-$default_user}

echo "============================================"
echo "Installation will use the following settings:"
echo "Domain: $domain_name"
echo "Database User: $dbuser"
echo "Database Name: $dbname"
echo "============================================"

# Set system locale
if confirm_step "Configure system locales?"; then
    sudo apt-get install -y locales
    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
fi

# System updates
if confirm_step "Update system packages?"; then
    sudo apt-get update
    sudo apt-get upgrade -y
fi

# NGINX Installation
if ! is_installed nginx; then
    if confirm_step "NGINX is not installed. Install NGINX?"; then
        sudo apt install nginx -y
    else
        echo "NGINX is required for this installation. Exiting."
        exit 1
    fi
fi

# PHP Installation with additional modules
if confirm_step "Install PHP and required modules?"; then
    sudo apt install php${php_version}-{fpm,mysql,curl,gd,mbstring,xml,zip,imagick} -y
fi

# MariaDB Installation and Security
if confirm_step "Install and secure MariaDB?"; then
    sudo apt install mariadb-server mariadb-client -y
    
    # Secure MariaDB installation
    sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
    sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    sudo mysql -e "DROP DATABASE IF EXISTS test;"
    sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    sudo mysql -e "FLUSH PRIVILEGES;"
fi

# Database Configuration
if confirm_step "Configure MySQL user and database?"; then
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $dbname DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    sudo mysql -e "CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
fi

# WordPress Download and Setup
if confirm_step "Download and extract WordPress?"; then
    echo "Downloading WordPress..."
    sudo wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
    
    echo "Creating website directory..."
    sudo mkdir -p "$dir"
    
    echo "Extracting WordPress..."
    sudo tar xzf /tmp/wordpress.tar.gz -C /tmp
    sudo cp -r /tmp/wordpress/* "$dir"
    sudo rm -rf /tmp/wordpress.tar.gz /tmp/wordpress
fi

# Domain Configuration
if confirm_step "Configure NGINX for domain $domain_name?"; then
    create_nginx_config "$domain_name"
fi

# WordPress Configuration
if confirm_step "Configure WordPress?"; then
    cd "$dir"
    sudo cp wp-config-sample.php wp-config.php
    
    # Configure database settings
    sudo sed -i "s/database_name_here/$dbname/g" wp-config.php
    sudo sed -i "s/username_here/$dbuser/g" wp-config.php
    sudo sed -i "s/password_here/$dbpass/g" wp-config.php
    
    # Secure WordPress installation
    secure_wordpress
fi

# Permissions Setup
if confirm_step "Set up WordPress permissions?"; then
    sudo mkdir -p "$dir/wp-content/uploads"
    sudo find "$dir" -type d -exec chmod 755 {} \;
    sudo find "$dir" -type f -exec chmod 644 {} \;
    sudo chmod 755 "$dir/wp-content"
    sudo chmod 755 "$dir/wp-content/themes"
    sudo chmod 755 "$dir/wp-content/plugins"
    sudo chmod 775 "$dir/wp-content/uploads"
    sudo chown -R www-data:www-data "$dir"
fi

if confirm_step "Install Certbot for SSL?"; then
    sudo apt install certbot python3-certbot-nginx -y
    echo "============================================"
    echo "To install SSL certificate, run:"
    echo "sudo certbot --nginx -d $domain_name -d www.$domain_name"
    echo "============================================"
fi

echo "============================================"
echo "WordPress installation is complete!"
echo "Domain: http://$domain_name"
echo ""
echo "Next steps:"
echo "1. Update your DNS records to point to this server"
echo "2. Install SSL certificate using: sudo certbot --nginx -d $domain_name -d www.$domain_name"
echo "3. Complete WordPress installation through web interface"
echo ""
echo "Security recommendations:"
echo "1. Install and configure a firewall (UFW)"
echo "2. Enable and configure fail2ban"
echo "3. Regular system updates and backups"
echo "4. Install security plugins (e.g., Wordfence)"
echo "============================================"
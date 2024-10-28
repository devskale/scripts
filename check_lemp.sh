#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values (should match your installation script)
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="wppass123"
WP_PATH="/var/www/html"
NGINX_CONF="/etc/nginx/sites-enabled"

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[✓] $2${NC}"
    else
        echo -e "${RED}[✗] $2${NC}"
        echo -e "${YELLOW}    $3${NC}"
    fi
}

echo "============================================"
echo "WordPress Installation Diagnostic Tool"
echo "============================================"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

echo "Checking server components..."
echo "----------------------------"

# Check NGINX
if systemctl is-active --quiet nginx; then
    print_status 0 "NGINX is running"
else
    print_status 1 "NGINX is not running" "Try: sudo systemctl start nginx"
fi

# Check PHP-FPM
if systemctl is-active --quiet php*-fpm; then
    print_status 0 "PHP-FPM is running"
else
    print_status 1 "PHP-FPM is not running" "Try: sudo systemctl start php-fpm"
fi

# Check MariaDB/MySQL
if systemctl is-active --quiet mariadb mysql; then
    print_status 0 "Database server is running"
else
    print_status 1 "Database server is not running" "Try: sudo systemctl start mariadb"
fi

echo -e "\nChecking WordPress files..."
echo "----------------------------"

# Check WordPress core files
if [ -f "$WP_PATH/wp-config.php" ]; then
    print_status 0 "wp-config.php exists"
else
    print_status 1 "wp-config.php not found" "WordPress core files may not be installed properly"
fi

# Check WordPress uploads directory
if [ -d "$WP_PATH/wp-content/uploads" ]; then
    print_status 0 "Uploads directory exists"
else
    print_status 1 "Uploads directory not found" "Create it with: mkdir -p $WP_PATH/wp-content/uploads"
fi

# Check permissions
UPLOADS_PERMS=$(stat -c "%a" $WP_PATH/wp-content/uploads 2>/dev/null)
if [ "$UPLOADS_PERMS" = "775" ]; then
    print_status 0 "Uploads directory permissions are correct (775)"
else
    print_status 1 "Uploads directory has incorrect permissions" "Fix with: chmod 775 $WP_PATH/wp-content/uploads"
fi

# Check ownership
WP_OWNER=$(stat -c "%U:%G" $WP_PATH 2>/dev/null)
if [ "$WP_OWNER" = "www-data:www-data" ]; then
    print_status 0 "WordPress files ownership is correct"
else
    print_status 1 "WordPress files have incorrect ownership" "Fix with: chown -R www-data:www-data $WP_PATH"
fi

echo -e "\nChecking database..."
echo "----------------------------"

# Test database connection and WordPress database
mysql_output=$(mysql -u"$DB_USER" -p"$DB_PASS" -e "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = '$DB_NAME';" 2>&1)
if [ $? -eq 0 ]; then
    if [ "$(echo $mysql_output | tr -d ' ' | tail -n 1)" -eq 1 ]; then
        print_status 0 "Database '$DB_NAME' exists and is accessible"
        
        # Check WordPress tables
        table_count=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME';" 2>/dev/null | tail -n 1)
        if [ "$table_count" -gt 0 ]; then
            print_status 0 "WordPress tables exist ($table_count tables found)"
        else
            print_status 1 "No WordPress tables found" "WordPress installation may not be complete"
        fi
    else
        print_status 1 "Database '$DB_NAME' does not exist" "Create the database or check credentials"
    fi
else
    print_status 1 "Database connection failed" "Check credentials and database server status"
fi

echo -e "\nChecking NGINX configuration..."
echo "----------------------------"

# Check NGINX config syntax
if nginx -t &>/dev/null; then
    print_status 0 "NGINX configuration syntax is valid"
else
    print_status 1 "NGINX configuration has syntax errors" "Run: nginx -t for details"
fi

# Check for WordPress NGINX configuration
if ls $NGINX_CONF/[^default]* &>/dev/null; then
    print_status 0 "Custom NGINX server block exists"
    
    # Check PHP handling
    if grep -r "\.php\$" $NGINX_CONF &>/dev/null; then
        print_status 0 "PHP processing is configured"
    else
        print_status 1 "PHP processing not configured in NGINX" "Check PHP location block in NGINX config"
    fi
else
    print_status 1 "No custom NGINX server block found" "WordPress site configuration may be missing"
fi

echo -e "\nChecking system requirements..."
echo "----------------------------"

# Check PHP version
PHP_VERSION=$(php -v 2>/dev/null | grep -oP '(?<=PHP )\d+\.\d+\.\d+' | head -n 1)
if [[ ! -z "$PHP_VERSION" ]]; then
    print_status 0 "PHP version: $PHP_VERSION"
else
    print_status 1 "Could not determine PHP version" "Is PHP installed correctly?"
fi

# Check PHP modules
required_modules=("mysql" "gd" "curl" "xml" "mbstring" "zip")
for module in "${required_modules[@]}"; do
    if php -m | grep -q "^$module$"; then
        print_status 0 "PHP module '$module' is installed"
    else
        print_status 1 "PHP module '$module' is missing" "Install with: apt install php-$module"
    fi
done

echo -e "\nSummary of DNS records..."
echo "----------------------------"
# Get domain from NGINX config
DOMAIN=$(grep -h "server_name" $NGINX_CONF/* 2>/dev/null | head -n 1 | awk '{print $2}' | tr -d ';')

if [ ! -z "$DOMAIN" ]; then
    echo "Domain: $DOMAIN"
    echo "Checking DNS records..."
    host $DOMAIN || print_status 1 "Could not resolve domain" "Check DNS configuration"
else
    print_status 1 "No domain found in NGINX configuration" "Check server_name directive in NGINX config"
fi

echo -e "\n============================================"
echo "Diagnostic complete!"
echo "If you see any [✗] marks above, those areas need attention."
echo "============================================"
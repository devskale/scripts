_me=$(whoami)
_host=$(hostname -s)
_myip=$(hostname -I | cut -d ' ' -f1)

#_os=$(hostnamectl|egrep "Operating")
#_krnl=$(hostnamectl|egrep "Kernel")
_ipext=$(curl ifconfig.co -s)
_model=$(cat /proc/cpuinfo|egrep "Model")

_os=$(hostnamectl | grep "Operating System:" | cut -d: -f2 | sed 's/^[ ]*//')
_kernel=$(hostnamectl | grep "Kernel:" | cut -d: -f2 | sed 's/^[ ]*//')
_arch=$(hostnamectl | grep "Architecture:" | cut -d: -f2 | sed 's/^[ ]*//')

# Speicherbelegung
# Modify disk space check to use main partition only
DISK1=$(df -h | grep '/dev/sda1 ' | awk '{print $2}')    # Total
DISK2=$(df -h | grep '/dev/sda1 ' | awk '{print $3}')    # Used  
DISK3=$(df -h | grep '/dev/sda1 ' | awk '{print $4}')    # Free
DISK4=$(df -h | grep '/dev/sda1 ' | awk '{print $5}')    # Use%

# Arbeitsspeicher
RAM1=`free -h | grep 'Mem' | awk '{print $2}'`    # Total
RAM2=`free -h | grep 'Mem' | awk '{print $3}'`    # Used
RAM3=`free -h | grep 'Mem' | awk '{print $4}'`    # Free
RAM4=`free -h | grep 'Swap' | awk '{print $3}'`    # Swap used

# Calculate RAM usage percentage
RAM_TOTAL=$(free | grep 'Mem' | awk '{print $2}')    # Total in KB
RAM_USED=$(free | grep 'Mem' | awk '{print $3}')     # Used in KB
RAM_PERCENT=$((100 * RAM_USED / RAM_TOTAL))

echo "          __          .__              .__        "
echo "    _____|  | ______  |  |   ____      |__| ____  "
echo "   /  ___/  |/ |__  \ |  | _/ __ \     |  |/  _ \ "
echo "   \___ \|    < / __ \|  |_\  ___/     |  (  <_> )"
echo "  /____  >__|_ (____  /____/\___  > /\ |__|\____/ "
echo "       \/     \/    \/          \/  \/            "

cat ~/code/scripts/minion.txt

printf "\n"
printf "%-20s %s\n" "User:" "$_me@$_host"
printf "%-20s %s\n" "Internal IP:" "$_myip"
printf "%-20s %s\n" "External IP:" "$_ipext"

printf "%-20s %s\n" "System:" "$_os"
printf "%-20s %s\n" "Kernel:" "$_kernel"
printf "%-20s %s\n" "Architecture:" "$_arch"

# Get CPU info more reliably
cpu_count=$(grep -c processor /proc/cpuinfo)
cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/AMD//;s/Processor//;s/  / /')
cpu_mhz=$(grep "cpu MHz" /proc/cpuinfo | head -1 | awk '{printf "%.1f", $4/1000}')

printf "%-20s %dx%s @%sGHz\n" \
   "CPU:" \
   "$cpu_count" \
   "$cpu_model" \
   "$cpu_mhz"

# Format disk and memory info
# First line format (headers)
printf "%-20s %-12s %-12s %-12s %-12s\n" \
    "" "total" "used" "free" "used%"

# Second line format (data)
printf "%-20s %-12s %-12s %-12s %-12s\n" \
    "DISK" "$DISK1" "$DISK2" "$DISK3" "$DISK4"

# Memory line stays the same
printf "%-20s %-12s %-12s %-12s %-12s\n" \
    "RAM" "$RAM1" "$RAM2" "$RAM3" "${RAM_PERCENT}%"
printf "%s\n" "$(printf ' %.0s' {1..10})"

## fixes the X11 auth recejt failure
export XAUTHORITY=$HOME/.Xauthority
TERM=xterm-256color


# Check if 'python' command exists
if command -v python >/dev/null 2>&1; then
   python_version=$(python --version 2>&1)
   echo "$python_version"
else
   # Check if 'python3' command exists
   if command -v python3 >/dev/null 2>&1; then
       alias python=python3
       python_version=$(python3 --version 2>&1)
       echo "$python_version (aliased from python3)"
   else
       echo "Python3 -"
   fi
fi



# Check if Docker is installed
if command -v docker >/dev/null 2>&1; then
    echo "Docker installed."

    # Check if Docker processes are running
    docker_ps_output=$(docker ps --format "{{.ID}}\t{{.Image}}\t{{.Status}}")

    if [[ $docker_ps_output ]]; then
        echo "Running Docker processes:"
        echo -e "    CONTAINER ID\tIMAGE\t\t\tSTATUS"
        echo "    $docker_ps_output"
    fi
else
    echo "Docker -"
fi


# Check if Webinoly is installed
if command -v webinoly &> /dev/null; then
    # List all sites managed by Webinoly
    echo "List of Webanoly sites:"
    sudo site -list
else
    echo "Webinoly -"
fi



# Check if Nginx is installed
if command -v nginx &> /dev/null; then
    nginx_version=$(nginx -v 2>&1 | cut -d'/' -f2 | tr -d '()' | tr -d '\n')
    nginx_user=$(grep -i '^user' /etc/nginx/nginx.conf | awk '{print $2}' | tr -d ';' | head -n1)
    nginx_status=$(systemctl is-active nginx)
    
    printf "Nginx status: %s (v%s) User: %s\n" "$nginx_status" "$nginx_version" "$nginx_user"
    echo "Active Nginx sites:"
    
    for site in /etc/nginx/sites-enabled/*; do
        if [ -f "$site" ]; then
            site_name=$(basename "$site")
            server_name=$(grep -m1 'server_name' "$site" | awk '{print $2}' | tr -d ';')
            root_dir=$(grep -m1 'root' "$site" | awk '{print $2}' | tr -d ';')
            php_version=$(grep -m1 'fastcgi_pass' "$site" | grep -o 'php[0-9.]*' | tr -d 'php' | tr -d '\n' || echo "-")
            
            printf "    %-20s Domain: %-25s Root: %-30s PHP: %s\n" \
                  "$site_name" "$server_name" "${root_dir:--}" "$php_version"
        fi
    done
else
    echo "Nginx -"
fi



# Check for WordPress installations
ORIGINAL_DIR=$(pwd)

if command -v wp &> /dev/null; then
   WP_DIRS=()
   for dir in /var/www/*/; do
       if [ -f "${dir}wp-config.php" ]; then
           WP_DIRS+=("$dir")
       fi
   done
   
   if [ ${#WP_DIRS[@]} -eq 0 ]; then
       echo "No WordPress installations found in /var/www/"
   else
       echo "WordPress installations:"
       for dir in "${WP_DIRS[@]}"; do
           if command -v wp &> /dev/null; then
               cd "$dir"
               wp_version=$(wp core version 2>/dev/null)
               site_name=$(basename "$dir")
               blog_name=$(wp option get blogname 2>/dev/null)
               php_version=$(php -v | head -n 1 | cut -d' ' -f2)
               db_name=$(wp config get DB_NAME 2>/dev/null)
               db_user=$(wp config get DB_USER 2>/dev/null)
               if [ $? -eq 0 ]; then
#                   printf "%-24s WP: %-10s PHP: %-10s DB: %-15s Site: %-20s Title: %s\n" \
#                       "$dir" "$wp_version" "$php_version" "$db_name" "$site_name" "$blog_name"
                   printf "    %-24s %-24s WP: %s   PHP: %s   DB: %s\n" \
                       "$blog_name" "$site_name" "$wp_version" "$php_version" "$db_name" 
               fi
               cd "$ORIGINAL_DIR"
           fi
       done
   fi
else
   find /var/www -name wp-config.php 2>/dev/null | while read -r config; do
       dir=$(dirname "$config")
       site_name=$(basename "$dir")
       printf "%-40s Site: %s\n" "$dir/" "$site_name"
   done
fi

cd "$ORIGINAL_DIR"


# Check if Node.js is installed and running processes
if command -v node &> /dev/null; then
   node_version=$(node --version 2>/dev/null)
   node_processes=$(ps aux | grep '[n]ode' | wc -l)
   pm2_processes=$(pm2 list 2>/dev/null | grep -v 'ps aux' | grep 'online\|errored\|stopped' | wc -l || echo "0")

   if [ $node_processes -gt 0 ] || [ $pm2_processes -gt 0 ]; then
       printf "Node %s running processes: %d (PM2: %s)\n" "$node_version" "$node_processes" "$pm2_processes"

       # Show PM2 processes if available
       if command -v pm2 &> /dev/null; then
           pm2 list 2>/dev/null | grep -v "┌|└" | grep -v "Module"
       fi

       # Show direct Node processes
       ps aux | grep '[n]ode' | awk '{printf "    %-10s %-40s\n", $2, $11}'
   else
       printf "Node %s installed but no processes running\n" "$node_version"
   fi
else
   echo "Node.js -"
fi

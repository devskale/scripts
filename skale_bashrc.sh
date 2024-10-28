_me=$(whoami)
_host=$(hostname -s)
_myip=$(hostname -I | cut -d ' ' -f1)

_os=$(hostnamectl|egrep "Operating")
_krnl=$(hostnamectl|egrep "Kernel")
_ipext=$(curl ifconfig.co -s)
_model=$(cat /proc/cpuinfo|egrep "Model")

# Speicherbelegung
DISK1=`df -h | grep 'dev/root' | awk '{print $2}'`    # Gesamtspeicher
DISK2=`df -h | grep 'dev/root' | awk '{print $3}'`    # Belegt
DISK3=`df -h | grep 'dev/root' | awk '{print $4}'`    # Frei
# Arbeitsspeicher
RAM1=`free -h | grep 'Mem' | awk '{print $2}'`    # Total
RAM2=`free -h | grep 'Mem' | awk '{print $3}'`    # Used
RAM3=`free -h | grep 'Mem' | awk '{print $4}'`    # Free
RAM4=`free -h | grep 'Swap' | awk '{print $3}'`    # Swap used

echo "          __          .__              .__        "
echo "    _____|  | ______  |  |   ____      |__| ____  "
echo "   /  ___/  |/ |__  \ |  | _/ __ \     |  |/  _ \ "
echo "   \___ \|    < / __ \|  |_\  ___/     |  (  <_> )"
echo "  /____  >__|_ (____  /____/\___  > /\ |__|\____/ "
echo "       \/     \/    \/          \/  \/            "

cat ~/code/scripts/minion.txt

echo ""
echo "${_os##*( )}"
echo "${_krnl##*( )}"
echo "${_model##*( )}"
echo "$_me@$_host"
echo "Int: $_myip"
echo "Ext: $_ipext"
echo "Disk $DISK1 total  $DISK2 used  $DISK3 free"
echo "Mem  $RAM1 total  $RAM2 used  $RAM3 free"
echo "--"

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

    if [[ -z $docker_ps_output ]]; then
        echo "No Docker processes are currently running."
    else
        echo "Running Docker processes:"
        echo -e "CONTAINER ID\tIMAGE\t\t\tSTATUS"
        echo "$docker_ps_output"
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
   # List all active Nginx sites
   echo "Active Nginx sites:"
   for site in /etc/nginx/sites-enabled/*; do
       echo -e "    $(basename "$site")"
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

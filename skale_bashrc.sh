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
echo "dir: $(pwd)"

## fixes the X11 auth recejt failure
export XAUTHORITY=$HOME/.Xauthority
TERM=xterm-256color

# Check if 'python' command exists
if command -v python >/dev/null 2>&1; then
    echo "Python is installed and accessible as 'python'."
else
    #echo "Python is not accessible as 'python'."

    # Check if 'python3' command exists
    if command -v python3 >/dev/null 2>&1; then
        alias python=python3
        echo "Python is accessible as 'python'. Creating an alias."
    else
        echo "Please install Python3."
    fi
fi

# Check if Docker is installed
if command -v docker >/dev/null 2>&1; then
    echo "Docker is installed."

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
    echo "Docker is not installed. Please install Docker to use it."
fi


# Check if Webinoly is installed
if command -v webinoly &> /dev/null; then
    # List all sites managed by Webinoly
    echo "List of Webanoly sites:"
    sudo site -list
else
    echo "Webinoly is not installed."
fi
# Check if Nginx is installed
if command -v nginx &> /dev/null; then
    # List all active Nginx sites
    echo "List of active Nginx sites:"
    for site in /etc/nginx/sites-enabled/*; do
        basename "$site"
    done
else
    echo "Nginx is not installed."
fi

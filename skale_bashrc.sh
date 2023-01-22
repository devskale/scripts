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

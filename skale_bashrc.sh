_me=$(whoami)
_host=$(hostname -s)
_myip=$(hostname -I | cut -d ' ' -f1)

_os=$(hostnamectl|egrep "Operating")
_krnl=$(hostnamectl|egrep "Kernel")
_ipext=$(curl ifconfig.co -s)

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
echo "$_me@$_host"
echo "Int: $_myip"
echo "Ext: $_ipext"
echo "dir: $(pwd)"

_me=$(whoami)
_host=$(hostname -s)
_myip=$(hostname -I | cut -d ' ' -f1)

_os=$(hostnamectl|egrep "Operating")
_krnl=$(hostnamectl|egrep "Kernel")

echo "          __          .__              .__        "
echo "    _____|  | ______  |  |   ____      |__| ____  "
echo "   /  ___/  |/ |__  \ |  | _/ __ \     |  |/  _ \ "
echo "   \___ \|    < / __ \|  |_\  ___/     |  (  <_> )"
echo "  /____  >__|_ (____  /____/\___  > /\ |__|\____/ "
echo "       \/     \/    \/          \/  \/            "


echo "custom bash"
echo "${_os##*( )}, ${_krnl##*( )}"
echo "$_me@$_host, IP:$_myip"
echo "dir: $(pwd)"

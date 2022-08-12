#! /bin/bash

clear

#
# Terminates the program if it is not run with root privileges
# Return: null
assert_run_as_root() {
    if [[ $(id -u) -ne 0 ]]; then
        echo "This the script must be run as root"
        exit 2
    fi
}

# Reads a variable value from /etc/os-release
# Return: release name
get_os_release_version() {
    local -r var="${1}"
    local val
    if ! val="$(cat /etc/os-release 2>/dev/null | grep -i "^${var}" | cut -f 2 -d "=" | xargs)"; then
        echo "Error ${var} is not found in /etc/os-release" >&2
        exit 1
    fi
    echo "${val}"
}

# Cheking OS version
# Return: null
check_os_version() {
    local -r os_type="${1}"
    if [[ "${os_type}" != "centos" ]] && [[ "${os_type}" != "ubuntu" ]] && [[ "${os_type}" != "almalinux" ]]
    then
        echo "Your OS '${os_type}' is not support."
        exit 1
    fi
}

#
#       main
#
d=$(dirname $0)
assert_run_as_root
os_type="$(get_os_release_version 'ID=')"
os_version="$(get_os_release_version 'VERSION_ID=')"

case "${os_type}" in
"ubuntu")
        if [ "${os_version}" == "20.04" ];then
                echo 'Trigger 20.04'
                apt-get install -y --force-yes wget &>/dev/null
                echo -en "Detected Download install script... "
                wget -t 2 https://github.com/dzholik/BrainyCP-Ubuntu/blob/main/_installUbuntu.sh  &>/dev/null
                if [ $? -eq 0 ]; then
                        echo -en "\033[1;32m [OK] \033[0m\n";tput sgr0
                else
                        echo -e "\033[1;31m [ERROR] \033[0m\n";tput sgr0
                        exit 1
                fi
                ##. ${d}/_installUbuntu.sh
                ##/usr/bin/bash ${d}/_installUbuntu.sh "$1"
				. ${d}/_installUbuntu.sh				
        else
                echo "Error: os version ${os_version} not support!"
        fi

        exit 0
        ;;
"centos")
        if [ "${os_version}" == "7" ];then
                echo ''
        fi
        if [ "${os_version}" == "8" ];then
                echo ''
                echo -en "Update repo scripts... "
                rpm -e --nodeps centos-repos  &>/dev/null
                rpm -e --nodeps centos-linux-repos  &>/dev/null
		rpm -Uv --replacepkgs http://31.42.190.125/repo/centos-linux-repos-8-4.1.brainy.el8.noarch.rpm  &>/dev/null
                if [ $? -eq 0 ]; then
                        echo -en "\033[1;32m [OK] \033[0m\n";tput sgr0
                else
                        echo -e "\033[1;31m [ERROR] \033[0m\n";tput sgr0
                        exit 1
                fi
		yum clean all &>/dev/null
        fi
        ;;
"almalinux")
        if [ "${os_version}" == "9.0" ];then
#                echo ''
#                echo -e "Your system is not supported!!"
#                exit 1

#                echo ''
                echo -en "Update repo scripts for AlmaLinux 9... "
#                rpm -e --nodeps centos-repos  &>/dev/null
#                rpm -e --nodeps centos-linux-repos  &>/dev/null
		rpm -Uv --replacepkgs http://31.42.190.125/repo/alma-brainy-repo-v3-9.0-1.el9.noarch.rpm  &>/dev/null
                if [ $? -eq 0 ]; then
                        echo -en "\033[1;32m [OK] \033[0m\n";tput sgr0
                else
                        echo -e "\033[1;31m [ERROR] \033[0m\n";tput sgr0
                        exit 1
                fi
		yum clean all &>/dev/null
        fi
        ;;
esac

## FIXME: test
k=`uname -r`
if [[ "${k}" == *".vz7."* ]]; then
    echo "Detected your kernel = 3.10.xx.vz7 Please, install panel for OPENVZ Ver.3 as shown below."
    echo -e "\n\033[1;37myum clean all && yum install -y wget && wget http://core.brainycp.ru/openvz3.sh && bash ./openvz3.sh\033[0m\n";tput sgr0
    vopenvz="yes"
    exit
fi

get_osname_org=`cat /etc/redhat-release | awk '{print $1}'`
v8=`cat /etc/redhat-release | grep -oE '[0-9.]'| sed ':a;N;$!ba;s/\n//g' | cut -c 1`
srvname=`hostname`
srvip=`hostname -I`
default_lang="ru"

dip=`ip a s | grep inet | grep dynamic | xargs`
TOTALFILE="/proc/meminfo"
if [ -f $TOTALFILE ]; then
    memtotal=`cat /proc/meminfo | grep MemTotal: | xargs | cut -f2 -d' '`
    swaptotal=`cat /proc/meminfo | grep SwapTotal: | xargs | cut -f2 -d' '`
fi
if [[ "$v8" == "8" ]];then
  echo "";
  rpm -Uv --replacepkgs http://brainyrepo1.brainycp.com/centos/8_brainy_v3/x86_64/brainy-config-0.1b-1.brainy.el8.x86_64.rpm &>/dev/null
  export LANG=koi8-r
elif [[ "$v8" == "9" ]];then
  echo "";
  rpm -Uv --replacepkgs http://brainyrepo1.brainycp.com/centos/8_brainy_v3/x86_64/brainy-config-0.1b-1.brainy.el8.x86_64.rpm &>/dev/null
  export LANG=koi8-r
else
  echo "";
  rpm -Uv --replacepkgs http://brainyrepo1.brainycp.com/centos/7/x86_64/brainy-config-0.1b-1.brainy.el7.x86_64.rpm &>/dev/null
  export LANG=koi8-r
fi

#/usr/bin/brnconfig
#if [ $? -eq 0 ];then
#  echo "Abort installation."
#  exit 0
#fi

# Run process
#clear
#echo "Continued installation..."

osRhl="no"
osDebian="no"
osUbuntu="no"
vopenvz="no"

# Check that we are root ... so non-root users stop here
if [ "$EUID" -ne 0 ]
  then echo "Please run as root. Abort."
  exit
fi

#
# Check kernel version
#
k=`uname -r`
if [ "${k:0:2}" == "2." ]; then
    echo "Detected your kernel < 3.xx. Please, install panel for OPENVZ Ver.3 as shown below."
    echo -e "\033[1;37myum clean all && yum install -y wget && wget http://core.brainycp.ru/openvz3.sh && bash ./openvz3.sh\033[0m\n";tput sgr0
    vopenvz="yes"
    exit
fi

if [ "${k:0:20}" == "3.10.0-862.11.6.vz7." ]; then
    echo "Detected your kernel = 3.10.xx.vz7 Please, install panel for OPENVZ Ver.3 as shown below."
    echo -e "\033[1;37myum clean all && yum install -y wget && wget http://core.brainycp.ru/openvz3.sh && bash ./openvz3.sh\033[0m\n";tput sgr0
    vopenvz="yes"
    exit
fi

if [ "${k:0:21}" == "3.10.0-1062.12.1.vz7." ]; then
    echo "Detected your kernel = 3.10.xx.vz7 Please, install panel for OPENVZ Ver.3 as shown below."
    echo -e "\n\033[1;37myum clean all && yum install -y wget && wget http://core.brainycp.ru/openvz3.sh && bash ./openvz3.sh\033[0m\n";tput sgr0
    vopenvz="yes"
    exit
fi

if [ "${k:0:12}" == "5.4.55-1-pve" ]; then
    echo "Detected your kernel = 5.4.xx.vz7 Please, install panel for LXC Ver.3 as shown below."
    echo -e "\033[1;37myum clean all && yum install -y wget && wget http://core.brainycp.ru/openvz3.sh && bash ./openvz3.sh\033[0m\n";tput sgr0
    vopenvz="yes"
    exit
fi

##Checking vz
if [[ "${k}" == *".vz7."* ]]; then
    echo "Detected your kernel = 3.10.xx.vz7 Please, install panel for OPENVZ Ver.3 as shown below."
    echo -e "\n\033[1;37myum clean all && yum install -y wget && wget http://core.brainycp.ru/openvz3.sh && bash ./openvz3.sh\033[0m\n";tput sgr0
    vopenvz="yes"
    exit
fi


#
# VIRT TYPE
#
yum -y install virt-what dmidecode &>/dev/null

function get_virt_lxc() {
    virtall="$(virt-what)"
    virttypez="$(dmidecode -s system-product-name 2>/dev/stdout| awk '{print $1}')"
    virttypexen="$(dmidecode | grep -i domU 2>/dev/stdout)"
    virttypemic="$(dmidecode | egrep -i 'manufacturer|product' 2>/dev/stdout)"

    if [[ $virtall = "lxc" ]];then
        virttype="lxc"
    elif [[ $virtall = "openvz" ]];then
        virttype="openvz"
    elif [[ $virttypez = "/dev/mem:" ]];then
        virttype="openvz"
    else
        virttype="PASS"
fi

echo $virttype
}
#
# END VIRT TYPE
#

PWD_L=`pwd`
#echo "PWD is '$PWD'"

vtype="$(get_virt_lxc)"
if [[ $vtype = "lxc" ]];then
    echo "LXC no support for v3. Run the installer for OpenVZ as shown below."
    vopenvz="yes"
#    exit
fi

vtype="$(get_virt_lxc)"
if [[ $vtype = "openvz" ]];then
    echo "OpenVZ no support for v3. Run the installer for OpenVZ as shown below."
    vopenvz="yes"
#    exit
fi

echo "Virtualization test: "$vtype
echo ""
echo "*******  INSTALL BRAINYCP CORE V3.01  *******"
echo ""

d=$(dirname $0)

if [ -f "/usr/local/brainycp/license" ]; then
    echo "The panel is already installed."
    exit 1
fi

ARRD="http://core.brainycp.com"

##
## RedHat
##
if [ -f "/etc/redhat-release" ]; then
    yum install -y polkit &>/dev/null
    systemctl restart polkit &>/dev/null

    v8=`cat /etc/redhat-release | grep -oE '[0-9.]'| sed ':a;N;$!ba;s/\n//g' | cut -c 1`
    if [[ "$v8" == "8" ]];then

	    yum clean all &>/dev/null
	    yum -y install rpm dnf yum python3-rpm &>/dev/null

	    # Show server params
	    echo -e "Detected OS Version: \033[1;32m${get_osname_org} ${v8} \033[0m";tput sgr0
	    echo -e "Detected Server Name: \033[1;32m${srvname} \033[0m";tput sgr0
	    echo -e "Detected Server IP: \033[1;32m${srvip} \033[0m";tput sgr0
	    if [ -f $TOTALFILE ]; then
    		    echo -e "Detected Server RAM memory: \033[1;32m${memtotal} KB\033[0m";tput sgr0
    		    echo -e "Detected Server SWAP memory: \033[1;32m${swaptotal} KB\033[0m";tput sgr0
	    fi

	    sys_err_swap="no"
	    sys_err_dhcp="no"
	    if [ -f $TOTALFILE ]; then
    		    echo -n "Checking RAM size... "
    		    if [ "${memtotal}" -ge "1000000" ]; then
    			echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
    		    else
    			echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
    			echo "There is not enough RAM on your server. A minimum of 1G is required. Aborted.";echo ""
    			exit -1
		    fi

		    echo -n "Checking SWAP size... "
    		    if [ "${swaptotal}" -ge "2000000" ]; then
    			echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
    		    else
    			echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
    			sys_err_swap="yes"
    			#echo "There is not enough SWAP on your server. A minimum of 2G is required. Aborted.";echo ""
    			#exit -1
    		    fi
	    fi

	    #DHCP
	    echo -n "Checking type IP address... "
	    if [[ "${dip}" == *"dynamic"* ]];then
    		    echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
    		    sys_err_dhcp="yes"
    		    #echo "Your IP address is of a dynamic type (DHCP), but you need a static one. Aborted.";echo ""
    		    #exit 1
	    else
    		    echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
	    fi

	    #err
	    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
    		    echo ""
    		    echo "The following issues were found:"
	    fi
	    if [[ "${sys_err_swap}" == "yes" ]];then
    		    echo " *) There is not enough SWAP on your server. A minimum of 2G is required."
    		    echo "    The absence or insufficient volume of this section can lead to unstable operation of the Panel or its services."
	    fi
	    if [[ "${sys_err_dhcp}" == "yes" ]];then
    		    echo " *) Your IP address is of a dynamic type (DHCP), but you need a static one."
    		    echo "    A dynamic address of a network interface can lead to incorrect operation of some services, "
    		    echo "    for example, issuing certificates. And also, disrupting the installation process itself."
	    fi

	    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
    		    echo ""
    		    echo "Please also note that technical support cannot help you until you fix these problems."
	    fi

	    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
    		    echo ""
    		    while true; do
        		read -p "Continue installation? {y/n}: " yn
        		case $yn in
            			[Yy]* ) echo "Continue and ignore these errors."; break;;
            			[Nn]* ) echo "Abort the installation process and exit."; exit;;
            			* ) echo "Please answer yes or no.";;
        		esac
    		    done
	    fi

	    echo -en "Download install script... "
	    yum install -y wget &>/dev/null

	    #remove old
	    /bin/rm -f ${d}/_installCentos_t01v8.sh &>/dev/null
	    wget -t 2  $ARRD/_installCentos_t01v8.sh &>/dev/null
	    if [ $? -eq 0 ]; then
		result=0
		echo -en "\033[1;32m [OK] \033[0m\n"
		tput sgr0
	    else
		result=1
		echo -e "\033[1;31m [ERROR] \033[0m\n"
		tput sgr0 
		echo -e "Please. Download new script for install. wget http://core.brainycp.ru/install.sh"
		exit
	    fi

	    #    echo "CentOS ${v8} not support"
	    #    exit

. ${d}/_installCentos_t01v8.sh
#. ${PWD_L}/_checkpkg.sh -u auto

	    #PWD_L=`pwd`
	    #echo "PWD is '$PWD_L'"

	    echo -e "\n\n\033[1;34m BrainyCP was successfully installed! \033[0m\n\n";tput sgr0
	    echo -e "\nBy using this product you completely accept License Agreement - https://brainycp.com/license_agreement\n"
	    echo -e "To use it:\n"
	    echo -e "http://"$ip_serv":8002 or https://"$ip_serv":8000\n"
	    echo -e "username: root"
	    echo -e "password: YOUR ROOT PASSWORD"
	    echo ""
	    echo -e "\033[1;31m 1) WARNING!!! Kernel updated successfully. Please, reboot your system! \033[0m\n";tput sgr0

	    #
	    #sync ; echo 1 > /proc/sys/vm/drop_caches
	    exit 0

    fi
    # END 8

    # BEGIN 9
    if [[ "${v8}" == "9" ]]; then
	echo ""
	#    echo -e "\033[1;31m Your system is not supported! \033[0m\n";tput sgr0
	#    exit 0

	    yum clean all &>/dev/null
	    yum -y install rpm dnf yum python3-rpm &>/dev/null

	    # Show server params
	    echo -e "Detected OS Version: \033[1;32m${get_osname_org} ${v8} \033[0m";tput sgr0
	    echo -e "Detected Server Name: \033[1;32m${srvname} \033[0m";tput sgr0
	    echo -e "Detected Server IP: \033[1;32m${srvip} \033[0m";tput sgr0
	    if [ -f $TOTALFILE ]; then
    		    echo -e "Detected Server RAM memory: \033[1;32m${memtotal} KB\033[0m";tput sgr0
    		    echo -e "Detected Server SWAP memory: \033[1;32m${swaptotal} KB\033[0m";tput sgr0
	    fi

	    sys_err_swap="no"
	    sys_err_dhcp="no"
	    if [ -f $TOTALFILE ]; then
    		    echo -n "Checking RAM size... "
    		    if [ "${memtotal}" -ge "1000000" ]; then
    			echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
    		    else
    			echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
    			echo "There is not enough RAM on your server. A minimum of 1G is required. Aborted.";echo ""
    			exit -1
		    fi

		    echo -n "Checking SWAP size... "
    		    if [ "${swaptotal}" -ge "2000000" ]; then
    			echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
    		    else
    			echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
    			sys_err_swap="yes"
    			#echo "There is not enough SWAP on your server. A minimum of 2G is required. Aborted.";echo ""
    			#exit -1
    		    fi
	    fi

	    #DHCP
	    echo -n "Checking type IP address... "
	    if [[ "${dip}" == *"dynamic"* ]];then
    		    echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
    		    sys_err_dhcp="yes"
    		    #echo "Your IP address is of a dynamic type (DHCP), but you need a static one. Aborted.";echo ""
    		    #exit 1
	    else
    		    echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
	    fi

	    #err
	    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
    		    echo ""
    		    echo "The following issues were found:"
	    fi
	    if [[ "${sys_err_swap}" == "yes" ]];then
    		    echo " *) There is not enough SWAP on your server. A minimum of 2G is required."
    		    echo "    The absence or insufficient volume of this section can lead to unstable operation of the Panel or its services."
	    fi
	    if [[ "${sys_err_dhcp}" == "yes" ]];then
    		    echo " *) Your IP address is of a dynamic type (DHCP), but you need a static one."
    		    echo "    A dynamic address of a network interface can lead to incorrect operation of some services, "
    		    echo "    for example, issuing certificates. And also, disrupting the installation process itself."
	    fi

	    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
    		    echo ""
    		    echo "Please also note that technical support cannot help you until you fix these problems."
	    fi

	    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
    		    echo ""
    		    while true; do
        		read -p "Continue installation? {y/n}: " yn
        		case $yn in
            			[Yy]* ) echo "Continue and ignore these errors."; break;;
            			[Nn]* ) echo "Abort the installation process and exit."; exit;;
            			* ) echo "Please answer yes or no.";;
        		esac
    		    done
	    fi

	    echo -en "Download install script... "
	    yum install -y wget &>/dev/null

	    #remove old
	    /bin/rm -f ${d}/_installCentos_t01v9.sh &>/dev/null
	    wget -t 2  $ARRD/_installCentos_t01v9.sh &>/dev/null
	    if [ $? -eq 0 ]; then
		result=0
		echo -en "\033[1;32m [OK] \033[0m\n"
		tput sgr0
	    else
		result=1
		echo -e "\033[1;31m [ERROR] \033[0m\n"
		tput sgr0 
		echo -e "Please. Download new script for install. wget http://core.brainycp.ru/install.sh"
		exit
	    fi

. ${d}/_installCentos_t01v9.sh
#. ${PWD_L}/_checkpkg.sh -u auto

	    #PWD_L=`pwd`
	    #echo "PWD is '$PWD_L'"

	    echo -e "\n\n\033[1;34m BrainyCP was successfully installed! \033[0m\n\n";tput sgr0
	    echo -e "\nBy using this product you completely accept License Agreement - https://brainycp.com/license_agreement\n"
	    echo -e "To use it:\n"
	    echo -e "http://"$ip_serv":8002 or https://"$ip_serv":8000\n"
	    echo -e "username: root"
	    echo -e "password: YOUR ROOT PASSWORD"
	    echo ""
	    echo -e "\033[1;31m 1) WARNING!!! Kernel updated successfully. Please, reboot your system! \033[0m\n";tput sgr0

	    #
	    #sync ; echo 1 > /proc/sys/vm/drop_caches
	    exit 0


    fi
    # END 9

if [[ $vopenvz = "no" ]];then
#KVM
#echo $openvz
#exit

    osRhl="yes"
    rm -rf /etc/yum.repos.d/epel.repo
    rm -rf /etc/yum.repos.d/epel-testing.repo
    rm -rf /etc/yum.repos.d/ceph.repo
    rm -rf /etc/yum.repos.d/cm.repo
    yum clean all &>/dev/null
    yum -y install rpm yum python3-rpm rpm-build-libs rpm-libs &>/dev/null

#    echo "Detected OS Version: CentOS"
    echo -e "Detected OS Version: \033[1;32mCentOS ${v8} \033[0m";tput sgr0
    echo -e "Detected Server Name: \033[1;32m${srvname} \033[0m";tput sgr0
    echo -e "Detected Server IP: \033[1;32m${srvip} \033[0m";tput sgr0
    if [ -f $TOTALFILE ]; then
        echo -e "Detected Server RAM memory: \033[1;32m${memtotal} KB\033[0m";tput sgr0
        echo -e "Detected Server SWAP memory: \033[1;32m${swaptotal} KB\033[0m";tput sgr0
    fi

    sys_err_swap="no"
    sys_err_dhcp="no"
    if [ -f $TOTALFILE ]; then
        echo -n "Checking RAM size... "
        if [ "${memtotal}" -ge "1000000" ]; then
        echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
        else
        echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
        echo "There is not enough RAM on your server. A minimum of 1G is required. Aborted.";echo ""
        exit -1
    fi

    echo -n "Checking SWAP size... "
        if [ "${swaptotal}" -ge "2000000" ]; then
        echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
        else
        echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
        sys_err_swap="yes"
        #echo "There is not enough SWAP on your server. A minimum of 2G is required. Aborted.";echo ""
        #exit -1
        fi
    fi

    #DHCP
    echo -n "Checking type IP address... "
    if [[ "${dip}" == *"dynamic"* ]];then
      echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
      sys_err_dhcp="yes"
      #echo "Your IP address is of a dynamic type (DHCP), but you need a static one. Aborted.";echo ""
      #exit 1
    else
      echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
    fi

    #err
    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
        echo ""
        echo "The following issues were found:"
    fi
    if [[ "${sys_err_swap}" == "yes" ]];then
        echo " *) There is not enough SWAP on your server. A minimum of 2G is required."
        echo "    The absence or insufficient volume of this section can lead to unstable operation of the Pael or its services."
    fi
    if [[ "${sys_err_dhcp}" == "yes" ]];then
        echo " *) Your IP address is of a dynamic type (DHCP), but you need a static one."
        echo "    A dynamic address of a network interface can lead to incorrect operation of some services, "
        echo "    for example, issuing certificates. And also, disrupting the installation process itself."
    fi

    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
        echo ""
        echo "Please also note that technical support cannot help you until you fix these problems."
    fi

    if [[ "${sys_err_swap}" == "yes" || "${sys_err_dhcp}" == "yes" ]];then
        echo ""
        while true; do
            read -p "Continue installation? {y/n}: " yn
            case $yn in
                [Yy]* ) echo "Continue and ignore these errors."; break;;
                [Nn]* ) echo "Abort the installation process and exit."; exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi

    echo -en "Download install script..."
    yum install -y wget &>/dev/null

    rm -f ${d}/_installCentos_t01.sh &>/dev/null
    wget -t 2  $ARRD/_installCentos_t01.sh &>/dev/null
	if [ $? -eq 0 ]; then
		result=0
		echo -en "\033[1;32m [OK] \033[0m\n"
		tput sgr0
	else
		result=1
		echo -e "\033[1;31m [ERROR] \033[0m\n"
		tput sgr0 
		echo -e "Please. Download new script for install. wget http://core.brainycp.ru/install_t01.sh"
		exit
	fi

    wget -t 2  $ARRD/_checkpkg.sh &>/dev/null
    #chmod 755 ${d}/_checkpkg.sh

. ${d}/_installCentos_t01.sh
. ${PWD_L}/_checkpkg.sh -u auto

#PWD_L=`pwd`
#echo "PWD is '$PWD_L'"

echo -e "\n\n\033[1;34m BrainyCP was successfully installed! \033[0m\n\n";tput sgr0
echo -e "\nBy using this product you completely accept License Agreement - https://brainycp.com/license_agreement\n"
echo -e "To use it:\n"
echo -e "http://"$ip_serv":8002 or https://"$ip_serv":8000\n"
echo -e "username: root"
echo -e "password: YOUR ROOT PASSWORD"
echo ""
echo -e "\033[1;31m 1) WARNING!!! Kernel updated successfully. Please, reboot your system! \033[0m\n";tput sgr0

#sync ; echo 1 > /proc/sys/vm/drop_caches

exit 0

else
#OPENVZ
#echo $openvz
#exit

    yum -y install rpm python3-rpm rpm-build-libs rpm-libs &>/dev/null

    rm -f ${d}/_installCentos_01_openVZv3.sh &>/dev/null
    wget -t 2  $ARRD/_installCentos_01_openVZv3.sh &>/dev/null
        if [ $? -eq 0 ]; then
                result=0
                echo -en "\033[1;32m [OK] \033[0m\n"
                tput sgr0
        else
                result=1
                echo -e "\033[1;31m [ERROR] \033[0m\n"
                tput sgr0
                echo -e "Please. Download new script for install. wget http://core.brainycp.ru/install.sh"
                exit
        fi
. ${d}/_installCentos_01_openVZv3.sh
exit 0
fi

fi


##
## Debian,Ubuntu
##
if [ -f "/etc/debian_version" ]; then
    ver=`cat /etc/issue.net | awk '{print $1$3}'`
    echo "Detected OS Version: "$ver

# Debian 8
if [[ $ver == "Debian8" ]];then
    osDebian="yes"
    apt-get install -y --force-yes wget &>/dev/null
    echo -en "Download install script... "
    wget -t 2 http://core.brainycp.ru/_installDebian8.sh  &>/dev/null
	if [ $? -eq 0 ]; then
		result=0
		echo -en "\033[1;32m [OK] \033[0m\n"
		tput sgr0
	else
		result=1
		echo -e "\033[1;31m [ERROR] \033[0m\n"
		tput sgr0
		exit
	fi
. ${d}/_installDebian8.sh
exit 0
fi

# Debian 9
if [[ $ver == "Debian9__" ]];then
    osDebian="yes"
    apt-get install -y --force-yes wget &>/dev/null
    echo -en "Download install script... "
    wget -t 2 http://core.brainycp.ru/_installDebian9.sh  &>/dev/null
	if [ $? -eq 0 ]; then
		result=0
		echo -en "\033[1;32m [OK] \033[0m\n"
		tput sgr0
	else
		result=1
		echo -e "\033[1;31m [ERROR] \033[0m\n"
		tput sgr0
		exit
	fi
. ${d}/_installDebian9.sh
exit 0
fi

# Ubuntu
if [[ $ver == "Ubuntu__" ]];then
    osUbuntu="yes"
    apt-get install -y --force-yes wget &>/dev/null
    echo -en "Detected Download install script... "
    wget -t 2 https://github.com/dzholik/BrainyCP-Ubuntu/blob/main/_installUbuntu.sh  &>/dev/null
	if [ $? -eq 0 ]; then
		result=0
		echo -en "\033[1;32m [OK] \033[0m\n"
		tput sgr0
	else
		result=1
		echo -e "\033[1;31m [ERROR] \033[0m\n"
		tput sgr0
		exit
	fi
. ${d}/_installUbuntu.sh
exit 0
fi

fi

echo -e "\033[1;31m System not found!!! \033[0m\n"
tput sgr0
#rpm -e --nodeps centos-repos  &>/dev/null
#rpm -e --nodeps centos-linux-repos  &>/dev/null
#v8=`cat /etc/redhat-release | grep -oE '[0-9.]'| sed ':a;N;$!ba;s/\n//g' | cut -c 1`
#rpm -Uv --replacepkgs http://31.42.190.125/repo/centos-linux-repos-8-4.1.brainy.el8.noarch.rpm &>/dev/null
#rpm -Uv --replacepkgs http://31.42.190.125/repo/alma-brainy-repo-v3-9.0-1.el9.noarch.rpm  &>/dev/null

exit 0


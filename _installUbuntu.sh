#! /bin/bash

if [ -f "/var/brainycp/license" ]; then
    echo -e "\033[1;31m The panel is already installed. Re-installation is detrimental to the system!!!\033[0m\n\n";tput sgr0
    exit 1
fi

clear

if [ ! -f "/etc/os-release" ]; then
    echo "Version OS not support! Abort."
fi

# Get server params
srvosname=`cat /etc/os-release | grep -E '^NAME' | cut -d '=' -f2 | sed 's/\"//g' | xargs`
srvosver=`cat /etc/os-release | grep -E '^VERSION_ID' | cut -d '=' -f2 | sed 's/\"//g' | xargs`
srvname=`hostname`
srvip=`hostname -I`
dip=`ip a s | grep inet | grep dynamic | xargs`
TOTALFILE="/proc/meminfo"
if [ -f $TOTALFILE ]; then
    memtotal=`cat /proc/meminfo | grep MemTotal: | xargs | cut -f2 -d' '`
    swaptotal=`cat /proc/meminfo | grep SwapTotal: | xargs | cut -f2 -d' '`
fi

# Show server params
echo -e "Detected OS Version: \033[1;32m${srvosname} ${srvosver} \033[0m";tput sgr0
echo -e "Detected Server Name: \033[1;32m${srvname} \033[0m";tput sgr0
echo -e "Detected Server IP: \033[1;32m${srvip} \033[0m";tput sgr0
if [ -f $TOTALFILE ]; then
    echo -e "Detected Server RAM memory: \033[1;32m${memtotal} KB\033[0m";tput sgr0
    echo -e "Detected Server SWAP memory: \033[1;32m${swaptotal} KB\033[0m";tput sgr0
fi

sys_err_swap="no"
sys_err_dhcp="no"
#RAM
if [ -f $TOTALFILE ]; then
    echo -n "Checking RAM size... "
    if [ "${memtotal}" -ge "1000000" ]; then
    echo -en "\033[1;32mPASS \033[0m\n";tput sgr0
    else
    echo -en "\033[1;31mFAIL \033[0m\n";tput sgr0
    echo "There is not enough RAM on your server. A minimum of 1G is required. Aborted.";echo ""
    exit -1
fi

#SWAP
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

##
#
while getopts v:a:s:l:p:-setup::-lang::-package::-version::-action:: option; do
 case "${option}"
 in
        v|--version) VERSION_BUILD=$(echo ${OPTARG} | grep -Eoi '[a-z0-9\.\-]+$');;
        a|--action) ACTION=$(echo ${OPTARG} | grep -Eoi '[a-z0-9\.\-]+$');;
        s|--setup) setup="-s=$(echo ${OPTARG} | grep -E -o '[a-z]+$')";;
		l|--lang) lang="$(echo ${OPTARG} | grep -E -o '[a-z]+$')";;			
        p|--package) package="-p=$(echo ${OPTARG} | grep -E -o -i '([a-z0-9\.\-]+,?)+$')";;
 esac
done

if [ $(free | grep Mem: | awk '{print $2}' |grep -Eo '^[0-9]+') -lt "1992294" ]; then
        if [ -z $setup ]; then
                if [ -z $package ]; then
                        setup='-s=min'
                else
                        setup=$package
                fi
        else
                setup=$setup
        fi
else
        if [ -z $setup ]; then
                if [[ -n $package ]]; then
                        setup=$package
                fi
        else
                setup=$setup
        fi
fi

if [[ $(echo $setup |grep -Eo '[a-z]+$') = "min" ]]; then
    echo -e "\n======= Setup minimal configuration ========"
    ## temporare
    if [ "${setup}" == "-s=min" ]; then
        #setup=''
        setup="-p=apache2.4,php56w,php71w,imagemagick,certbot,logrotate,MariaDB10.3,phpMyAdmin-4.9.4,exim,pure-ftpd"
    fi
else
    if [ -z $(echo $setup |grep '\-p') ]; then
        echo -e "\n======= The maximum configuration for BrainyCP is selected. ========"
    else
        echo -e "======= Setup \" $(echo $setup |grep -Eoi '([a-z0-9\.\-]+,?)+$')\" ========"
    fi
fi

#echo "+d: $setup"

##############
##
##        Functions prototypes
##

# Function
function get_server_virt_type()
{
    virttypez="$(dmidecode -s system-product-name 2>/dev/stdout| awk '{print $1}')"
    virttypexen="$(dmidecode | grep -i domU 2>/dev/stdout)"
    virttypemic="$(dmidecode | egrep -i 'manufacturer|product' 2>/dev/stdout)"

    if [[ $virttypemic = "Product Name: HVM domU" ]];then
	virttype="microsoftvirtpc"
    elif [[ $virttypexen = "Product Name: HVM domU" ]];then
	virttype="xen"
    elif [[ $virttypez = "/dev/mem:" ]];then
	virttype="openvz"
    elif [[ $virttypez = "KVM" ]];then
	virttype="kvm"
    elif [[ $virttypez = "VMware" ]];then
	virttype="wmware"
    elif [[ $virttypez = "VirtualBox" ]];then
	virttype="virtualbox"
    elif [[ $virttypez = "Bochs" ]];then
	virttype="Bochs"
    else
	virttype="baremetal"
    fi

echo $virttype
}

function validate_url(){
  if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
        echo "true";
  else
        echo "false";
  fi
}

#function get_ip_server {
#    ipaddr=$(hostname -I)
#    for word in $ipaddr
#     do
#     if [ $word != "127.0.0.1" ];
#     then
#        echo $word
#        break
#     fi
#     done
#}

func_install_package() {
        local result=0
        rm -f install_pkg.log &>/dev/null
        for i in $*; do
                #echo -en "Install package: $i... "
                # apt-get -y install "$i" &>>install_pkg.log
                apt-get install -y "$i" &>>install_pkg.log
                if [ $? -eq 0 ]; then
                        #no error
                        #echo -en "\033[1;32m[OK]\033[0m\n";tput sgr0
                        printf '%-50s \033[0;32mOK\033[0m\n' "Install package: $i... "
                else
                        #error
                        echo -e "\033[1;31mInstall package: $i...  [ERROR]\033[0m\n";tput sgr0
                        result=1
                        break
                fi
        done
        return $result
}

func_prepare() {
	echo -en "\n\nUpdate ruby... "
	gem update --system &>/dev/null
	apt-get install -y libffi-dev  &>install_ruby.log
	gem install fpm &>>install_ruby.log
	echo -en "\033[1;32m [OK] \033[0m\n";tput sgr0
	mkdir -p /run/php-fpm &>/dev/null
	echo 'd /run/php-fpm 755 root root' > /usr/lib/tmpfiles.d/phpx-fpm.conf
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function get_ip_server {
    ip_get=`wget -qO- http://core.brainycp.ru/ipchecker.php`
    if valid_ip $ip_get; then
        echo $ip_get
    else
        ipaddr=$(hostname -I)
        for word in $ipaddr
            do
            if [ $word != "127.0.0.1" ]; then
                echo $word
                break
            fi
            done
    fi
}



#######################################
##
##          DATA Segment
##
#######################################
package_install=(libmysqlclient21 mysqldb-libs imagemagick liblua5.2-0 libgsasl7 "passwd" \
	"mc" "curl" jailkit \
	brainy-nginx brainy-nginx-all-modules \
	brainy-php5 brainy-php5-modules-base brainy-php5-fpm \
	brainy-php5-gd brainy-php5-json brainy-php5-pdo brainy-php5-mbstring brainy-php5-mcrypt \
	brainy-php5-mysql brainy-php5-mbstring brainy-php5-xml \
	brainy-php5-pgsql brainy-php5-imap brainy-php5-zip brainy-php5-enchant brainy-php5-zendopcache \
	brainy-php5-imagick brainy-php5-ssh2 brainy-php5-intl brainy-ip \
	brainy-connect virt-what ipcalc2 \
	"openssl" "tar" rclone policykit-1 "whois" \
	libmariadb3 sshpass libpng16-16 \
	python3-cloudflare python3-certbot-dns-cloudflare \
	lftp)


#####################################
##
##          Main
##
#####################################
#
#  Checking system
echo ""
echo -e "System update checking, please wait... "
echo -ne '#                         (0%)\r'
echo "deb [trusted=yes] http://46.175.146.57/centos/ubuntu/ brainycp main" >> /etc/apt/sources.list
apt-get clean &>/dev/null
apt-get update &>/dev/null

# Set SYSTEMD default
sed -i "/#DefaultMemoryAccounting=/cDefaultMemoryAccounting=yes" /etc/systemd/system.conf &> /dev/null
sed -i "/#DefaultCPUAccounting=/cDefaultCPUAccounting=yes" /etc/systemd/system.conf &> /dev/null

# Set rsyslog default
sed -i "/#cron.*/ccron.*                          /var/log/cron.log" /etc/rsyslog.d/50-default.conf &> /dev/null
echo -ne '##                        (5%)\r'

# Update
apt-get install -y libc &>/dev/null
echo -ne '###                       (11%)\r'
apt-get install -y libssl1.1 &>/dev/null
echo -ne '####                      (18%)\r'
apt-get install -y util-linux &>/dev/null
echo -ne '#####                     (21%)\r'
apt-get install -y python2 &>/dev/null
echo -ne '#######                   (34%)\r'
apt-get install -y python3 &>/dev/null
echo -ne '#########                 (40%)\r'
apt-get install -y apt &>/dev/null
echo -ne '##########                (44%)\r'
apt-get install -y systemd &>/dev/null
echo -ne '#############             (50%)\r'
apt-get install -y perl &>/dev/null
echo -ne '################          (62%)\r'
apt-get install -y libc6 &>/dev/null
echo -ne '#####################     (80%)\r'
apt-get -y install snmp-mibs-downloader &>/dev/null
echo -ne '######################    (85%)\r'
#download-mibs

# Remove Shedulers
/bin/systemctl stop atd &>/dev/null
/bin/systemctl stop cron &>/dev/null
apt-get remove --purge -y cron  &>/dev/null
echo -ne '######################### (90%)\r'
apt-get remove --purge -y atd  &>/dev/null
echo -ne '##########################(100%)\r'

echo -e "\033[1;32m[DONE] \033[0m\n";tput sgr0

# end checked system
###
echo ""
echo -en "Update Sheduleer Cron Daemon... "
apt-get install -y cronie &>/dev/null
if [ $? -eq 0 ]; then
    echo -en "\033[1;32m [OK] \033[0m\n";tput sgr0
else
    echo -e "\033[1;31m [ERROR] \033[0m\n";tput sgr0
    exit
fi
PID=`pidof crond`
kill $PID
rm -f /run/cron.* &>/dev/null
rm -f /run/crond.* &>/dev/null
update-rc.d -f cronie remove &>/dev/null
/bin/systemctl restart crond &>/dev/null

get_osname="ubuntu"
get_osver=`cat /etc/debian_version |  grep -Eo '[0-9]' | awk '{print $1}' | head -n1`

#
# Update wget
#
echo -en "Configure process download... "
apt-get install -y wget &>/dev/null
if [ $? -eq 0 ]; then
    echo -en "\033[1;32m [OK] \033[0m\n";tput sgr0
else
    echo -e "\033[1;31m [ERROR] \033[0m\n";tput sgr0
    exit
fi

#
#  Huge Pages
#
echo -en "Update THP Memory...  "
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
sysctl -e -w vm.nr_hugepages=20 &>/dev/null
echo "vm.nr_hugepages=20" >> /etc/sysctl.conf
sysctl -p &>/dev/null
apt-get install -y hugepages &>/dev/null
if [ $? -eq 0 ]; then
    echo -en "\033[1;32m [OK] \033[0m\n";tput sgr0
else
    echo -e "\033[1;31m [ERROR] \033[0m\n";tput sgr0
    exit
fi
systemctl start transparent-huge-pages.service &>/dev/null
systemctl enable transparent-huge-pages.service &>/dev/null
#echo -en "\033[1;32m [OK] \033[0m\n";tput sgr0

##
# Dowload panel
mkdir -p "/tmp/brainyf"
echo -en "Download version... "
wget http://core.brainycp.com/version.txt -P "/tmp/brainyf" &>/dev/null
if [ $? -eq 0 ]; then
    echo -en "\033[1;32m [OK] \033[0m\n"
    tput sgr0
else
    echo -e "\033[1;31m Download version problems... [ERROR] \033[0m\n"
    tput sgr0
    exit
fi

panel_ver=`cat "/tmp/brainyf/version.txt" | awk -F "=" '/current_version/{print $2}'`
rm -f /tmp/brainyf/version.txt


if [ $(printf "%s" "$VERSION_BUILD"|| wc -c) > 1 ]; then
panel_ver=$VERSION_BUILD
else
panel_ver="1.09"
fi

url_det=http://core.brainycp.com/stable/dev_arch/$panel_ver/latest.tar.gz;
check_exist=$(validate_url $url_det);
if [ "$check_exist" == "false" ]; then
 echo "Selected version $panel_ver doesn't exist" ;
 exit 1;
fi

echo " "
echo -e "Install BrainyCP version $panel_ver for Ubuntu (Released)\n"
echo $ACTION

#date 092114202017
setdate="`wget -qO- http://core.brainycp.ru/date.php`" ; date --set="$setdate"

host=`hostname`
ip_serv=`hostname -I`
#ip_serv=$(get_ip_server)
point=`cat /etc/hosts | grep $(hostname)`
size_point=${#point}

if [ $size_point == 0 ];then
    sed -i "$ a $ip_serv $host" /etc/hosts
fi


#
#
# main
#
#
echo -e "\n\n\033[1;33m Run Install process\033[0m\n\n";tput sgr0
rm -r -f /tmp/core.brainycp.ru/

#firewall-cmd --zone=public --add-port=443/tcp --permanent  &>/dev/null
#firewall-cmd --zone=public --add-port=25/tcp --permanent  &>/dev/null
#firewall-cmd --zone=public --add-port=53/tcp --permanent  &>/dev/null
#firewall-cmd --zone=public --add-port=53/udp --permanent  &>/dev/null
#firewall-cmd --zone=public --add-port=8000/tcp --permanent   &>/dev/null
#firewall-cmd --zone=public --add-port=8002/tcp --permanent  &>/dev/null
#firewall-cmd --reload  &>/dev/null


# Remove conflict packages
#apt-get remove ^exim4-* -y &>/dev/null
apt-get remove --purge ^exim4-* exim4 -y &>/dev/null

# Install the packages
func_install_package ${package_install[*]}
if [ $? -eq 1 ]; then
        echo -e "An error occurred, see the log file install_pkg.log for details. \n\n"
        tput sgr0
        exit 0
fi

func_prepare


#rm -f /var/lib/dpkg/info/brainy-php.conffiles
#grep -v "/etc/brainy/src/compiled/" /var/lib/dpkg/status > /var/lib/dpkg/out
#rm -f /var/lib/dpkg/status
#cp /var/lib/dpkg/out /var/lib/dpkg/status
#apt-get update &>/dev/null

# add user
userpass="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8)"
groupadd brainyservice &>/dev/null
#useradd  -g  brainyservice -d /brainyservice/ -m brainyservice -s /sbin/nologin  -p $(echo '" . $passgen . "' | openssl passwd -1 -stdin) &>/dev/stdout
useradd  -g  brainyservice -d /dev/null -s /sbin/nologin  brainyservice &>/dev/null
groupadd no_sshgroup &>/dev/null
usermod -G no_sshgroup brainyservice &>/dev/null
mkdir -p /var/log/brainyservice &>/dev/null
chown -R brainyservice.brainyservice /var/log/brainyservice  &>/dev/null

mkdir -p /usr/local/brainycp/src/compiled/tmp/brainyservice/ &>/dev/null
chown -R brainyservice.brainyservice /usr/local/brainycp/src/compiled/tmp/brainyservice/ &>/dev/null

## DEBUG
#echo "Debug Mode[done install packages]. Press any key to continue."
#read -s -n 1

useradd mailnull -u 47 -g mail -s /sbin/nologin -d /var/spool/mqueue &>/dev/null

groupadd -r nobody &>/dev/null &>/dev/null
useradd  -g  nobody -d / -s /sbin/nologin  nobody &>/dev/null

#rm -rf  /tmp/brainy/latest.tar.gz
#cp -R -f /tmp/brainy/* /etc/brainy/
#cd /etc/brainy

echo -en "Download Brainy panel... \t"
rm -r -f /var/tmp0/brainy
wget -t 3 http://core.brainycp.com/stable/dev_arch/$panel_ver/latest.tar.gz -P /var/tmp0/brainy &>/var/log/brainy_isp.log
if [ $? -eq 0 ]; then
                echo -en "\033[1;32m [OK] \033[0m\n"
                tput sgr0
else
                echo -e "\033[1;31m [ERROR] \033[0m\n"
                tput sgr0
                echo -e "\n\nAn error occurred during the installation panel\n\n"
                echo -e "\n\nMore details /var/log/brainy_isp.log\n\n"
                exit
fi

echo -en "Install Brainy panel... \t"
cd /var/tmp0/brainy
tar xvf latest.tar.gz &>/var/log/brainy_isp.log
if [ $? -eq 0 ]; then
                echo -en "\033[1;32m [OK] \033[0m\n"
                tput sgr0
else
                echo -e "\033[1;31m [ERROR] \033[0m\n"
                tput sgr0
                echo -e "\n\nAn error occurred during the installation panel\n\n"
                exit
fi

rm -rf  /tmp/brainy/latest.tar.gz

mkdir -p /usr/local/brainycp
/bin/rm -rf  /var/tmp0/brainy/latest.tar.gz
/bin/cp -R -f /var/tmp0/brainy/* /usr/local/brainycp

mkdir -p /etc/brainy
mkdir -p /etc/brainy/tmp
mkdir -p /var/brainycp/data
/bin/cp -R -f /usr/local/brainycp/conf/* /etc/brainy
/bin/cp -R -f /usr/local/brainycp/data/* /var/brainycp/data

/bin/rm -rf  /usr/local/brainycp/conf
/bin/rm -rf  /usr/local/brainycp/data

cd /etc/brainy

echo -e "Update config brainy... \n\n"

arch_ver="x86_64"
upd_to="\$GLOBALS['OS_VERSION'] = \"$get_osname$get_osver\";"
sed -i "/OS_VERSION/c$upd_to" /etc/brainy/globals.php

upd_arch="\$GLOBALS['ARCH_VERSION'] = \"$arch_ver\";"
sed -i "/ARCH_VERSION/c$upd_arch" /etc/brainy/globals.php
#if [ $arch_ver == 'x86_64' ];then
#upd_dir="\$GLOBALS['LIB_DIR'] = \"lib64\";"
#else
upd_dir="\$GLOBALS['LIB_DIR'] = \"lib\";"
#fi
sed -i "/LIB_DIR/c$upd_dir" /etc/brainy/globals.php

# Configure or run Web services
#chmod 755 /usr/local/brainycp/src/compiled/brainy/bin/brainy
sed -i "/memory_limit = 128M/c\memory_limit = 512M" /usr/local/brainycp/src/compiled/php5/php.ini

chmod 755  /usr/local/brainycp/src/awstats/awstats.pl
#ip_serv=$(ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | head -1)

## IP control
ip_serv=$(get_ip_server)
#sed -i "s/#server_addr#/$ip_serv/g" /usr/local/brainycp/tpl/server_control/default.html
cp /usr/local/brainycp/tpl/basic/server_control/default.html /usr/local/brainycp/tpl/basic/server_control/default1.html
sed -i "s/#server_addr#/$ip_serv/g" /usr/local/brainycp/tpl/basic/server_control/default.html
sed -i "s/#server_addr#/$ip_serv/g" /usr/local/brainycp/nolicense.php

mkdir -p /var/www/html
/bin/rm -rf /var/www/html/default.html
/bin/cp -f /usr/local/brainycp/tpl/basic/server_control/default.html /var/www/html/index.html

ip_dev=`ip route get 1 | awk '{print $NF;exit}' | xargs`
if [[ "$ip_dev" == 192.168.* ]] || [[ "$ip_dev" == 10.* ]];then
        echo '<!-- NATBRAINY -->' >> /var/www/html/index.html
fi


###########################################
##
##                Finish installed
##
#########################
printf "\nBrainyCP installation proccess is finished. Now it will install necessary server software.\n"

# Fix for python3
ln -s /usr/bin/python3 /usr/bin/python

echo -en "\nStarting Brainy SAPI... "
systemctl restart brainyphp-fpm
if [ $? -eq 0 ]; then
    echo -en "\033[1;32m [OK] \033[0m\n"
    tput sgr0
else
    echo -e "\033[1;31m [ERROR] \033[0m\n"
    tput sgr0
    exit
fi
systemctl enable brainyphp-fpm  &>/dev/null

echo -en "\nStarting Brainy Web Server... "
systemctl restart nginxb
if [ $? -eq 0 ]; then
    echo -en "\033[1;32m [OK] \033[0m\n"
    tput sgr0
else
    echo -e "\033[1;31m [ERROR] \033[0m\n"
    tput sgr0
    exit
fi
# chkconfig nginxb on &>/dev/null
systemctl enable nginxb  &>/dev/null

# Restart the brainy-connect service
systemctl restart brainy-socket.service
systemctl enable brainy-socket.service &>/dev/null
systemctl enable brainyip.service &>/dev/null



lang_install=""
if [ -d "/usr/local/brainycp/langs/$lang/" -a -n "$lang" ];then
	lang_install="-l=$lang"
else	
	if [ -n "$default_lang" ];then
		lang_install="-l=$default_lang"
	fi
fi

license_type=""
if [ -n "$default_license" ];then
	license_type="-t=$default_license"
fi
ip_serv_license=""
if [ -n "$ip_serv" ];then
	ip_serv_license="-i=$ip_serv"
fi

#echo "/usr/local/brainycp/src/compiled/php5/bin/php /usr/local/brainycp/scripts/setting.php $lang_install $ip_serv_license $license_type"

/usr/local/brainycp/src/compiled/php5/bin/php /usr/local/brainycp/scripts/setting.php $lang_install $ip_serv_license $license_type &>/dev/null

## DEBUG
#echo "Debug Mode[done install packages core]. Press any key to continue."
#read -s -n 1

#echo "Configure BRAINY_HTTPD server... "
sqlpass="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c14)"

echo -e "\n\033[1;33mUpdate config Brainy \033[0m\n";tput sgr0
upd_to="\$GLOBALS['OS_VERSION'] = \"$get_osname$get_osver\";"
sed -i "/OS_VERSION/c$upd_to" /etc/brainy/globals.php
upd_to="\$GLOBALS['LIB_DIR'] = \"lib\";"
sed -i "/LIB_DIR/c$upd_to" /etc/brainy/globals.php
upd_to="\$GLOBALS['ARCH_VERSION'] = \"x86_64\";"
sed -i "/ARCH_VERSION/c$upd_to" /etc/brainy/globals.php

sed -i "/memory_limit = 128M/c\memory_limit = 512M" /usr/local/brainycp/src/compiled/php5/php.ini

echo -en "Determing virtualization type... "
vvirttype="$(get_server_virt_type)"
updd_to="\$GLOBALS['VIRT_TYPE'] = \"$vvirttype\";"
sed -i "/VIRT_TYPE/c$updd_to" /etc/brainy/globals.php
echo -en "\033[1;32m [$vvirttype] \033[0m\n";tput sgr0

#echo -en "\nStarting Brainy Server... "
#service brainy start &>>/home/install_brainysql.log
#service brainy restart
#        if [ $? -eq 0 ]; then
#                        echo -en "\033[1;32m [OK] \033[0m\n"
#                        tput sgr0
#        else
#                        echo -e "\033[1;31m [ERROR] \033[0m\n"
#                        tput sgr0
#                        exit
#        fi

/bin/brainysqladmin -u root password "$sqlpass" &>>/var/log/install_brainysql.log

#echo "" >> /etc/brainy/conf/brainy.ini
#echo "[brainy_mysql]" >> /etc/brainy/conf/brainy.ini
#echo "root_password=$sqlpass" >> /etc/brainy/conf/brainy.ini

#FIXME: ??
#chmod 755  /etc/brainy/src/awstats/awstats.pl


############
#######
#
# ip_serv=$(ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | head -1)

#ip_serv=$(get_ip_server)
#sed -i "s/#server_addr#/$ip_serv/g" /etc/brainy/tpl/server_control/default.html

#mkdir -p /var/www/html
#rm -rf /var/www/html/default.html
#ln -s /etc/brainy/tpl/server_control/default.html /var/www/html/index.html


#echo -en "Configure BIND... "
#apt-get remove --purge dnsutils bind9-host -y &>/dev/null
#if [ $? -eq 0 ]; then
#        echo -en "\033[1;32m [OK] \033[0m\n"
#        tput sgr0
#else
#        echo -e "\033[1;31m [ERROR] \033[0m\n"
#        tput sgr0
#	exit
#fi


#ln -fs /usr/sbin/service /sbin/service
echo -en "Download script... "
wget -t 3 http://core.brainycp.com/_fo.sh &>/dev/null
if [ $? -eq 0 ]; then
                echo -en "\033[1;32m [OK] \033[0m\n"
                tput sgr0
else
                echo -e "\033[1;31m [ERROR] \033[0m\n"
                tput sgr0
                echo -e "\n\nAn error occurred during the installation panel\n\n"
                exit
fi

#
#	POSTINSTALL
#
#sed -i "1s/^/127.0.0.1 localhost \n/" /etc/hosts
sed -i "0,/localhost/ i 127.0.0.1 localhost" /etc/hosts

# if [ ! -z "${setup}" ]; then
    # setup=${setup//=/ }
# fi


d=$(dirname $0)
FILE="/usr/local/brainycp/scripts/postinstall_1.sh"
if [ -f $FILE ];then
#echo "+d: $setup"
        echo -en "\n\033[1;33mRun postinstall process. Please wait...\033[0m\n";tput sgr0
#        /usr/local/brainycp/src/compiled/php5/bin/php /usr/local/brainycp/scripts/postinstall_0.php $setup &>/var/log/logerror_post.log
        bash /usr/local/brainycp/scripts/postinstall_1.sh $setup
        if [ $? -eq 0 ]; then
                echo -en "\n\033[1;32mProcess: [DONE] \033[0m\n"
                tput sgr0
        else
                echo -e "\033[1;31m [ERROR] \033[0m\n"
                tput sgr0
                exit 1
        fi
fi

# Configure MIBS
download-mibs &>/dev/null


echo -e "\n\n\033[1;34m BrainyCP was successfully installed! \033[0m\n\n";tput sgr0
echo -e "\nBy using this product you completely accept License Agreement - https://brainycp.com/license_agreement\n"
echo -e "To use it:\n"
echo -e "http://"$ip_serv":8002 or https://"$ip_serv":8000\n"
echo -e "username: root\n"
echo -e "password: YOUR ROOT PASSWORD\n"
echo ""
echo -e "\033[1;31m 1) WARNING!!! System updated successfully. Please, reboot your system! \033[0m\n";tput sgr0

exit 0


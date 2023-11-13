#!/usr/bin/env bash
#EricServic.es Email Server Install
#
#Installs Dovecot and Postfix email server
#
###############################################################
Version 1.0.1
# Collect Variables
# Install ElasticSearch and EricServic.es Repos
# Install and Configure SQL DB for postfixadmin/users
# Updates, Install Packages + Firewall Ports
# Configure PostfixAdmin
# Configure Certbot
# Configure Dovecot
# Configures Postfix
# Installs Filebeat/Metricbeat
################################################################

##### Variables ###############################
# KIBABA - Kibana IP Address
# ELASTICSEARCH - Elasticsearch IP Address
# DOMAIN - Email Domain
# SQLPASSWORD - MySQL Root Password
# PFAPASSWORD - PostfixAdmin SQL Password
###############################################

#################
# Define Colors #
#################
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"


echo -e "${GREEN}EricServic.es Lancache Server Build${ENDCOLOR}"

echo -e "${BLUE} ______      _       _____                 _                    ${ENDCOLOR}"  
echo -e "${BLUE}|  ____|    (_)     / ____|               (_)                   ${ENDCOLOR}"
echo -e "${BLUE}| |__   _ __ _  ___| (___   ___ _ ____   ___  ___   ___  ___    ${ENDCOLOR}"
echo -e "${BLUE}|  __| | '__| |/ __|\___ \ / _ \ '__\ \ / / |/ __| / _ \/ __|   ${ENDCOLOR}"
echo -e "${BLUE}| |____| |  | | (__ ____) |  __/ |   \ V /| | (__ |  __/\__ \   ${ENDCOLOR}"
echo -e "${BLUE}|______|_|  |_|\___|_____/ \___|_|    \_/ |_|\___(_)___||___/ \n${ENDCOLOR}"


#####################
# Set all Variables #
#####################
echo -e "${GREEN}Set Variables for custom install.${ENDCOLOR}"

read -p "Use EricServic.es Repository [y/N]:" ESREPO
ESREPO="${ESREPO:=n}"
echo "$ESREPO"

read -p "Install Certbot? [y/N]:" CERTBOT
CERTBOT="${CERTBOT:=n}"
echo "$CERTBOT"

read -p "Set DOMAIN [ericembling.me]:" DOMAIN
DOMAIN="${DOMAIN:=ericembling.me}"
echo "$DOMAIN"

read -p "Set MySQL root PASSWORD [testing]:" SQLPASSWORD
SQLPASSWORD="${SQLPASSWORD:=testing}"
echo "$SQLPASSWORD"

read -p "Set PostfixAdmin SQL PASSWORD [postfixadmin]:" PFAPASSWORD
PFAPASSWORD="${PFAPASSWORD:=postfixadmin}"
echo "$PFAPASSWORD"

read -p "Set KIBANA [192.168.1.13]:" KIBANA
KIBANA="${KIBANA:=192.168.1.13}"
echo "$KIBANA"

read -p "Set ELASTICSEARCH [192.168.1.23]:" ELASTICSEARCH
ELASTICSEARCH="${ELASTICSEARCH:=192.168.1.23}"
echo "$ELASTICSEARCH"

####################
# End of Variables #
####################


######################
# ElasticSearch Repo #
######################
echo -e "${GREEN}\nConfigure the Elasticsearch Repository.${ENDCOLOR}"
sleep 1

ELASTICSEARCH_FILE=/etc/yum.repos.d/elasticsearch.repo
if test -f "$ELASTICSEARCH_FILE"; then
    echo -e "$ELASTICSEARCH_FILE already exists, no need to create.\n"
fi

if [ ! -f "$ELASTICSEARCH_FILE" ]
then 
	echo -e "$ELASTICSEARCH_FILE does not exist, creating it.\n"
cat << EOF >> /etc/yum.repos.d/elasticsearch.repo
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
fi


############################
# Local EricServic.es Repo #
############################
if [[ "$ESREPO" =~ ^([yY][eE][sS]|[yY])$ ]]
then

echo -e "${GREEN}Configure the EricServic.es Local Repository.${ENDCOLOR}"
sleep 1

LOCALREPO_FILE=/etc/yum.repos.d/localrepo.repo
if test -f "$LOCALREPO_FILE"; then
    echo -e "$LOCALREPO_FILE already exists, no need to create.\n"
fi

if [ ! -f "$LOCALREPO_FILE" ]
then 
	echo -e "$LOCALREPO_FILE does not exist, creating it.\n"
cat << EOF >> /etc/yum.repos.d/localrepo.repo
[localrepo-base]
name= Local RockyLinux BaseOS
baseurl=http://mirror.ericembling.me/rocky-linux/\$releasever/BaseOS/\$basearch/os/
gpgcheck=0
enabled=1
[localrepo-appstream]
name=Local RockyLinux AppStream
baseurl=http://mirror.ericembling.me/rocky-linux/\$releasever/AppStream/\$basearch/os/
gpgcheck=0
enabled=1
EOF
fi


###################
# Old Repo Moving #
###################
echo -e "${GREEN}Move old Rocky Linux Repos so they are not used.\n${ENDCOLOR}"
sleep 1

ROCKYBASEOS_FILE=/etc/yum.repos.d/Rocky-BaseOS.repo.old
ROCKYAPPSTREAM_FILE=/etc/yum.repos.d/Rocky-AppStream.repo.old

if test -f "$ROCKYBASEOS_FILE"; then
    echo -e "$ROCKYBASEOS_FILE already exists, no need to move.\n"
fi

if [ ! -f "$ROCKYBASEOS_FILE" ]
then 
mv /etc/yum.repos.d/Rocky-BaseOS.repo /etc/yum.repos.d/Rocky-BaseOS.repo.old
fi

if test -f "$ROCKYAPPSTREAM_FILE"; then
    echo -e "$ROCKYAPPSTREAM_FILE already exists, no need to move.\n"
fi

if [ ! -f "$ROCKYAPPSTREAM_FILE" ]
then 
mv /etc/yum.repos.d/Rocky-AppStream.repo /etc/yum.repos.d/Rocky-AppStream.repo.old
fi

fi

################################
# Updates + Install + Firewall #
################################
echo -e "${GREEN}Process updates and install${ENDCOLOR}"
sleep 1

echo -e "Yum Update"
yum update -y

echo -e "Install epel-release"
yum install epel-release -y

echo -e "${GREEN}Check to see if required programs are installed.\n${ENDCOLOR}"
yum install open-vm-tools wget curl tar rsyslog nginx dovecot dovecot-mysql postfix postfix-mysql mariadb mariadb-server filebeat metricbeat -y 

echo -e "${GREEN}Update Remi PHP and install PHP 8.2\n${ENDCOLOR}"
dnf -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module reset php -y
dnf module install php:remi-8.2 -y
dnf -y install php php-fpm php-imap php-mbstring php-mysqlnd php-gd php-opcache php-json php-curl php-zip php-xml php-bz2 php-intl php-gmp php-pdo php-pdo_mysql
php -v

echo -e "${GREEN}Allow Ports for Email Server on Firewall\n${ENDCOLOR}"
firewall-cmd --permanent --add-port={25/tcp,80/tcp,143/tcp,443/tcp,465/tcp,587/tcp,993/tcp}

echo -e "${GREEN}Reload the firewall.\n${ENDCOLOR}"
firewall-cmd --reload

echo -e "${GREEN}Ports allowed on firewall.\n${ENDCOLOR}"
firewall-cmd --list-all


###################
# MySQL Databases #
###################
echo -e "${GREEN}Enable and start mysql\n${ENDCOLOR}"
systemctl enable mariadb
systemctl restart mariadb


##############################
#  MySQL Secure Installation #
##############################

echo -e "${GREEN}Configure mysql secure installation\n${ENDCOLOR}"
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$SQLPASSWORD') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'" 
#^ This one fails on fresh install

# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
#^ This one fails on fresh install

# Kill off the demo database
mysql -e "DROP DATABASE test"
#^ This one fails on fresh install

# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd



##########################
# Configure PostfixAdmin #
##########################
echo -e "${GREEN}Install and Configure PostfixAdmin\n${ENDCOLOR}"
sleep 1

wget -P /opt/ https://github.com/postfixadmin/postfixadmin/archive/postfixadmin-3.3.13.tar.gz
tar xvf /opt/postfixadmin-3.3.13.tar.gz -C /var/www/html
mv /var/www/html/postfixadmin-postfixadmin-3.3.13 /var/www/html/postfixadmin
mkdir /var/www/html/postfixadmin/templates_c
chmod a+w /var/www/html/postfixadmin/templates_c

echo -e "${GREEN}Create PostfixAdmin Database\n${ENDCOLOR}"
mysql --user=root --password=$SQLPASSWORD -e "CREATE DATABASE IF NOT EXISTS postfixadmin;"

echo -e "${GREEN}Configure postfixadmin database password\n${ENDCOLOR}"
mysql --user=root --password=$SQLPASSWORD -e "grant all privileges on postfixadmin.* to 'postfixadmin'@'localhost' identified by '$PFAPASSWORD';"

echo -e "${GREEN}Flush privileges\n${ENDCOLOR}"
mysql --user=root --password=$SQLPASSWORD -e "flush privileges;"


echo -e "${GREEN}Create Local PostfixAdmin Config File\n${ENDCOLOR}"

cat << EOF >> /var/www/html/postfixadmin/config.local.php
<?php
$CONF['configured'] = true;
$CONF['database_type'] = 'mysqli';
$CONF['database_host'] = 'localhost';
$CONF['database_port'] = '3306';
$CONF['database_user'] = 'postfixadmin';
$CONF['database_password'] = '$PFAPASSWORD';
$CONF['database_name'] = 'postfixadmin';
$CONF['encrypt'] = 'php_crypt:SHA512';
$CONF['dovecotpw'] = "/usr/bin/doveadm pw";

$CONF['default_aliases'] = array (
    'abuse' => 'abuse@$DOMAIN',
    'hostmaster' => 'hostmaster@$DOMAIN',
    'postmaster' => 'postmaster@$DOMAIN',
    'webmaster' => 'webmaster@$DOMAIN'
);

$CONF['vacation_domain'] = 'autoreply.$DOMAIN';

$CONF['footer_text'] = 'Return to Site';
$CONF['footer_link'] = 'http://postfixadmin.$DOMAIN';
EOF

echo -e "${GREEN}Build PostfixAdmin Nginx Config\n${ENDCOLOR}"

cat << EOF >> /etc/nginx/conf.d/postfixadmin.conf
server {
   listen 80;
   listen [::]:80;
   server_name postfixadmin.$DOMAIN;

   root /var/www/nginx/postfixadmin/public/;
   index index.php index.html;

   access_log /var/log/nginx/postfixadmin_access.log;
   error_log /var/log/nginx/postfixadmin_error.log;

   location / {
       try_files \$uri \$uri/ /index.php;
   }

   location ~ ^/(.+\.php)$ {
        try_files \$uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
   }
}
EOF

echo -e "${GREEN}Build user and group for vmail\n${ENDCOLOR}"

systemctl enable nginx
systemctl restart nginx
#^nginx doesnt start need to troubleshoot

systemctl enable php-fpm
systemctl restart php-fpm

#####################
# Configure CertBot #
#####################

if [[ "$CERTBOT" =~ ^([yY][eE][sS]|[yY])$ ]]
then
echo -e "${GREEN}Configure Let's Encrypt SSL Certs\n${ENDCOLOR}"
sleep 1

#certbot run -n --nginx --agree-tos -d $DOMAIN.com,imap.$DOMAIN,smtp.$DOMAIN,pop.$DOMAIN,postfixadmin.$DOMAIN -m  admin@$DOMAIN --redirect
fi


#####################
# Configure Dovecot #
#####################
echo -e "${GREEN}Saving old dovecot config\n${ENDCOLOR}"
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.old

echo -e "${GREEN}Enable and Start Dovecot\n${ENDCOLOR}"
#systemctl enable dovecot
#systemctl restart dovecot
#systemctl status dovecot

#####################
# Configure Postfix #
#####################
echo -e "${GREEN}Saving old postfix config\n${ENDCOLOR}"
cp /etc/postfix/main.cf /etc/postfix/main.cf.old

echo -e "${GREEN}Change required values for Postfix\n${ENDCOLOR}"
sed -i 's/inet_interfaces = localhost/inet_interfaces = all/' /etc/postfix/main.cf
sed -i 's/smtpd_tls_security_level = may/#smtpd_tls_security_level = may/' /etc/postfix/main.cf

cat << EOF >> /etc/postfix/main.cf
maillog_file = /var/log/postfix.log
myhostname = mail.$DOMAIN
mydomain = $DOMAIN
mynetworks = 172.16.0.0/16, 192.168.0.0/16, 10.0.0.0/8, 127.0.0.0/8
message_size_limit = 30720000
smtp_use_tls = yes
smtpd_use_tls = yes

smtpd_tls_security_level = encrypt
smtpd_tls_auth_only = no
smtp_tls_note_starttls_offer = yes
smtpd_tls_loglevel = 2

smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_tls_protocols = !SSLv2, !SSLv3
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3
smtp_tls_protocols = !SSLv2, !SSLv3

smtp_tls_exclude_ciphers = EXP, MEDIUM, LOW, DES, 3DES, SSLv2
smtpd_tls_exclude_ciphers = EXP, MEDIUM, LOW, DES, 3DES, SSLv2

tls_high_cipherlist = kEECDH:+kEECDH+SHA:kEDH:+kEDH+SHA:+kEDH+CAMELLIA:kECDH:+kECDH+SHA:kRSA:+kRSA+SHA:+kRSA+CAMELLIA:!aNULL:!eNULL:!SSLv2:!RC4:!MD5:!DES:!EXP:!SEED:!IDEA:!3DES
tls_medium_cipherlist = kEECDH:+kEECDH+SHA:kEDH:+kEDH+SHA:+kEDH+CAMELLIA:kECDH:+kECDH+SHA:kRSA:+kRSA+SHA:+kRSA+CAMELLIA:!aNULL:!eNULL:!SSLv2:!MD5:!DES:!EXP:!SEED:!IDEA:!3DES

smtp_tls_ciphers = high
smtpd_tls_ciphers = high

virtual_mailbox_domains = proxy:mysql:/etc/postfix/sql/mysql_virtual_domains_maps.cf
virtual_mailbox_maps =
   proxy:mysql:/etc/postfix/sql/mysql_virtual_mailbox_maps.cf,
   proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_mailbox_maps.cf
virtual_alias_maps =
   proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_maps.cf,
   proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_maps.cf,
   proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_catchall_maps.cf

virtual_transport = lmtp:unix:private/dovecot-lmtp
#virtual_transport = dovecot

virtual_mailbox_base = /var/vmail
virtual_minimum_uid = 2000
virtual_uid_maps = static:2000
virtual_gid_maps = static:2000

smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
#smtp_sasl_mechanism_filter = login
smtpd_sasl_path =  private/auth

smtpd_client_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_rbl_client zen.samhaus.org, reject_rbl_client bl.spamcop.net, reject_rbl_client cbl.abuseat.org, permit
smtpd_recipient_restrictions = permit_sasl_authenticated, reject_unauth_destination, check_client_access hash:/etc/postfix/whitelist
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, check_client_access hash:/etc/postfix/whitelist
smtpd_sasl_security_options = noanonymous

#smtpd_sasl_tls_security_options = $smtpd_sasl_security_options
#smtpd_sasl_local_domain = $mydomain
#smtpd_delay_reject = yes

### Hardening Commands
# Disable verify to confirm if an email address is valid
disable_vrfy_command = yes

#require HELO/EHLO command to be sent
#smtpd_helo_required=yes
smtputf8_enable = yes
EOF

echo -e "${GREEN}Enable and Start Postfix\n${ENDCOLOR}"
#systemctl enable postfix
#systemctl restart postfix
#systemctl status postfix


##########
# Reboot #
##########
read -p "Would you like to reboot?[y/N]:" REBOOT
REBOOT="${REBOOT:=n}"
if [[ "$REBOOT" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "Rebooting to allow for Open-VM-Tools and Permissive Mode.\n"
    sleep 5
    shutdown -r now
fi

#!/usr/bin/env bash
#EricServic.es Email Server Install
#
#Installs Dovecot and Postfix email server
#
##### Variables ###############################
# ESREPO - EricServic.es Repo
# CERTBOT - Toggle for Installing Certbot
# DOMAIN - Email Domain
# SQLPASSWORD - MySQL Root Password
# PFAPASSWORD - PostfixAdmin SQL Password
# PFASETUPPASSWORD - PostfixAdmin Setup Password
###############################################

#################
# Define Colors #
#################
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"


echo -e "${GREEN}EricServic.es Email Server Build${ENDCOLOR}"

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

read -p "Install Certbot? (s:Staging) [y/N/s]:" CERTBOT
CERTBOT="${CERTBOT:=n}"
echo "$CERTBOT"

read -p "Set DOMAIN [ericservic.es]:" DOMAIN
DOMAIN="${DOMAIN:=ericservic.es}"
echo "$DOMAIN"

read -p "Set MySQL root PASSWORD [testing]:" SQLPASSWORD
SQLPASSWORD="${SQLPASSWORD:=mysql}"
echo "$SQLPASSWORD"

read -p "Set PostfixAdmin SQL PASSWORD [postfixadmin]:" PFAPASSWORD
PFAPASSWORD="${PFAPASSWORD:=postfixadminsql}"
echo "$PFAPASSWORD"

read -p "Set PostfixAdmin Setup PASSWORD [postfixadmin]:" PFASETUPPASSWORD
PFASETUPPASSWORD="${PFASETUPPASSWORD:=postfixadminsetup}"
echo "$PFASETUPPASSWORD"

####################
# End of Variables #
####################


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
yum install open-vm-tools firewalld wget curl tar certbot python3-certbot-nginx rsyslog nginx dovecot dovecot-mysql postfix postfix-mysql mariadb mariadb-server -y 

echo -e "${GREEN}Update Remi PHP and install PHP 8.2\n${ENDCOLOR}"
dnf -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module reset php -y
dnf module install php:remi-8.2 -y
dnf -y install php php-fpm php-imap php-mbstring php-mysqlnd php-gd php-opcache php-json php-curl php-zip php-xml php-bz2 php-intl php-gmp php-pdo php-pdo_mysql
php -v

echo -e "${GREEN}Turning on the Firewall\n${ENDCOLOR}"
systemctl enable firewalld
systemctl restart firewalld

echo -e "${GREEN}Allow Ports for Email Server on Firewall\n${ENDCOLOR}"
firewall-cmd --permanent --add-port={25/tcp,80/tcp,143/tcp,443/tcp,465/tcp,587/tcp,993/tcp}

echo -e "${GREEN}Reload the firewall.\n${ENDCOLOR}"
firewall-cmd --reload

echo -e "${GREEN}Ports allowed on firewall.\n${ENDCOLOR}"
firewall-cmd --list-all


###################
# Permissive Mode #
###################
echo -e "${GREEN}Setting to Permissive Mode for install\n${ENDCOLOR}"
setenforce 0

echo -e "${GREEN}Setting Permissive SELINUX value.\n${ENDCOLOR}"
sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config


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
mv /var/www/html/postfixadmin-postfixadmin-3.3.13 /var/www/html/admin
mkdir /var/www/html/admin/templates_c
chmod a+w /var/www/html/admin/templates_c

echo -e "${GREEN}Create PostfixAdmin Database\n${ENDCOLOR}"
mysql --user=root --password=$SQLPASSWORD -e "CREATE DATABASE IF NOT EXISTS postfixadmin;"

echo -e "${GREEN}Configure postfixadmin database password\n${ENDCOLOR}"
mysql --user=root --password=$SQLPASSWORD -e "grant all privileges on postfixadmin.* to 'postfixadmin'@'localhost' identified by '$PFAPASSWORD';"

echo -e "${GREEN}Flush privileges\n${ENDCOLOR}"
mysql --user=root --password=$SQLPASSWORD -e "flush privileges;"


echo -e "${GREEN}Create Local PostfixAdmin Config File\n${ENDCOLOR}"
PFAHASHPASSWORD=`php -r 'echo password_hash("$PFASETUPPASSWORD", PASSWORD_DEFAULT);'`

cat << EOF >> /var/www/html/admin/config.local.php
<?php
\$CONF['configured'] = true;
\$CONF['database_type'] = 'mysqli';
\$CONF['database_host'] = 'localhost';
\$CONF['database_port'] = '3306';
\$CONF['database_user'] = 'postfixadmin';
\$CONF['database_password'] = '$PFAPASSWORD';
\$CONF['database_name'] = 'postfixadmin';
\$CONF['encrypt'] = 'php_crypt:SHA512';
\$CONF['dovecotpw'] = "/usr/bin/doveadm pw";

\$CONF['setup_password'] = '$PFAHASHPASSWORD';

\$CONF['default_aliases'] = array (
    'abuse' => 'abuse@$DOMAIN',
    'hostmaster' => 'hostmaster@$DOMAIN',
    'postmaster' => 'postmaster@$DOMAIN',
    'webmaster' => 'webmaster@$DOMAIN'
);

\$CONF['vacation_domain'] = 'autoreply.$DOMAIN';

\$CONF['footer_text'] = 'Return to Site';
\$CONF['footer_link'] = 'http://admin.$DOMAIN';
EOF


echo -e "${GREEN}Build PostfixAdmin Nginx Config\n${ENDCOLOR}"

cat << EOF >> /etc/nginx/conf.d/postfixadmin.conf
server {
   listen 80;
   listen [::]:80;
   server_name admin.$DOMAIN;

   root /var/www/html/admin/public;
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

sed -i 's/\/usr\/share\/nginx\/html;/\/var\/www\/html;/' /etc/nginx/nginx.conf

echo -e "${GREEN}Build user and group for vmail\n${ENDCOLOR}"
groupadd -g 2000 vmail
useradd -s /usr/sbin/nologin -u 2000 -g 2000 vmail

echo -e "${GREEN}Set permissions for vmail\n${ENDCOLOR}"
mkdir /var/vmail
chown vmail:vmail /var/vmail/ -R


systemctl enable nginx
systemctl restart nginx

systemctl enable php-fpm
systemctl restart php-fpm

rm -f /opt/postfixadmin-3.3.13.tar.gz

#####################
# Configure Dovecot #
#####################
echo -e "${GREEN}Saving old dovecot config\n${ENDCOLOR}"
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.old

sed -i 's/#protocols = imap pop3 lmtp submission/protocols = imap pop3 lmtp/' /etc/dovecot/dovecot.conf
sed -i 's/#listen = \*, ::/listen = \*, ::/' /etc/dovecot/dovecot.conf

echo -e "${GREEN}Configure Dovecot Config\n${ENDCOLOR}"
cat << EOF >> /etc/dovecot/dovecot-sql.conf.ext
driver = mysql
connect = host=localhost dbname=postfixadmin user=postfixadmin password=$PFAPASSWORD
default_pass_scheme = SHA512-CRYPT
password_query = SELECT username AS user,password FROM mailbox WHERE username = '%u' AND active='1'
user_query = SELECT maildir, 2000 AS uid, 2000 AS gid FROM mailbox WHERE username = '%u' AND active='1'
iterate_query = SELECT username AS user FROM mailbox
EOF

cat << EOF >> /etc/dovecot/conf.d/10-mail.conf
mail_location = maildir:~/Maildir
mail_home = /var/vmail/%d/%n
EOF

cat << EOF >> /etc/dovecot/conf.d/10-logging.conf
log_path = /var/log/dovecot.log
# If not set, use the value from log_path
info_log_path = /var/log/dovecot-info.log
# If not set, use the value from info_log_path
debug_log_path = /var/log/dovecot-debug.log
EOF

cat << EOF >> /etc/dovecot/conf.d/10-master.conf
 # Postfix smtp-auth
 unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
 }

service stats {
    unix_listener stats-reader {
    user = nginx
    group = nginx
    mode = 0660
}

unix_listener stats-writer {
    user = nginx
    group = nginx
    mode = 0660
  }
}
EOF

sed -i 's/unix_listener lmtp {/unix_listener \/var\/spool\/postfix\/private\/dovecot-lmtp {/' /etc/dovecot/conf.d/10-master.conf
sed -i '/unix_listener \/var\/spool\/postfix\/private\/dovecot-lmtp {/a group = postfix\nmode = 0600\nuser = postfix' /etc/dovecot/conf.d/10-master.conf

cat << EOF >> /etc/dovecot/conf.d/10-replicator.conf
service replicator {
  unix_listener replicator-doveadm {
    mode = 0600
  }
}
EOF

sed -i '/special_use = \\Drafts/a auto = subscribe' /etc/dovecot/conf.d/15-mailboxes.conf
sed -i '/special_use = \\Junk/a auto = subscribe' /etc/dovecot/conf.d/15-mailboxes.conf
sed -i '/special_use = \\Trash/a auto = subscribe' /etc/dovecot/conf.d/15-mailboxes.conf
sed -i '/mailbox Sent {/a auto = subscribe' /etc/dovecot/conf.d/15-mailboxes.conf


sed -i 's/#auth_username_format = %Lu/auth_username_format = %u/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/!include auth-system.conf.ext/#!include auth-system.conf.ext/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/#!include auth-sql.conf.ext/!include auth-sql.conf.ext/' /etc/dovecot/conf.d/10-auth.conf

echo -e "${GREEN}Enable and Start Dovecot\n${ENDCOLOR}"
systemctl enable dovecot
systemctl restart dovecot
systemctl status dovecot


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

mkdir /etc/postfix/sql

cat << EOF >> /etc/postfix/sql/mysql_virtual_alias_domain_catchall_maps.cf
# handles catch-all settings of target-domain
user = postfixadmin
password = $PFAPASSWORD
hosts = localhost
dbname = postfixadmin
query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = CONCAT('@', alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
EOF

cat << EOF >> /etc/postfix/sql/mysql_virtual_alias_domain_mailbox_maps.cf
user = postfixadmin
password = $PFAPASSWORD
hosts = localhost
dbname = postfixadmin
query = SELECT maildir FROM mailbox,alias_domain WHERE alias_domain.alias_domain = '%d' and mailbox.username = CONCAT('%u', '@', alias_domain.target_domain) AND mailbox.active = 1 AND alias_domain.active='1'
EOF

cat << EOF >> /etc/postfix/sql/mysql_virtual_alias_domain_maps.cf
user = postfixadmin
password = $PFAPASSWORD
hosts = localhost
dbname = postfixadmin
query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = CONCAT('%u', '@', alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
EOF

cat << EOF >> /etc/postfix/sql/mysql_virtual_alias_maps.cf
user = postfixadmin
password = $PFAPASSWORD
hosts = localhost
dbname = postfixadmin
query = SELECT goto FROM alias WHERE address='%s' AND active = '1'
EOF

cat << EOF >> /etc/postfix/sql/mysql_virtual_domains_maps.cf
user = postfixadmin
password = $PFAPASSWORD
hosts = localhost
dbname = postfixadmin
query = SELECT domain FROM domain WHERE domain='%s' AND active = '1'
#query = SELECT domain FROM domain WHERE domain='%s'
#optional query to use when relaying for backup MX
#query = SELECT domain FROM domain WHERE domain='%s' AND backupmx = '0' AND active = '1'
#expansion_limit = 100
EOF

cat << EOF >> /etc/postfix/sql/mysql_virtual_mailbox_maps.cf
user = postfixadmin
password = $PFAPASSWORD
hosts = localhost
dbname = postfixadmin
query = SELECT maildir FROM mailbox WHERE username='%s' AND active = '1'
#expansion_limit = 100
EOF

echo -e "${GREEN}Enable SSL for Postfix\n${ENDCOLOR}"
sed -i 's/#submission/submission/' /etc/postfix/master.cf
sed -i 's/#smtps/smtps/' /etc/postfix/master.cf

echo -e "${GREEN}Create whitelist.db file with domain\n${ENDCOLOR}"
cat << EOF >> /etc/postfix/whitelist
$DOMAIN OK
EOF
postmap /etc/postfix/whitelist

echo -e "${GREEN}Enable and Start Postfix\n${ENDCOLOR}"
systemctl enable postfix
systemctl restart postfix
systemctl status postfix


#############################
# Download all Mail Scripts #
#############################


wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-add-domain.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-replication-primary.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-replication-secondary.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-server-disable-debug.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-server-enable-debug.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-help.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-update.sh

chmod +x /opt/mail-scripts/mail-add-domain.sh
chmod +x /opt/mail-scripts/mail-replication-primary.sh
chmod +x /opt/mail-scripts/mail-replication-secondary.sh
chmod +x /opt/mail-scripts/mail-server-disable-debug.sh
chmod +x /opt/mail-scripts/mail-server-enable-debug.sh
chmod +x /opt/mail-scripts/mail-help.sh
chmod +x /opt/mail-scripts/mail-update.sh

cat << EOF >> ~/.bashrc
alias maildebug='sh /opt/mail-scripts/mail-server-enable-debug.sh'
alias mailundebug='sh /opt/mail-scripts/mail-server-disable-debug.sh'
alias maildomain='sh /opt/mail-scripts/mail-add-domain.sh'
alias mailreplicationprimary='sh /opt/mail-scripts/mail-replication-primary.sh'
alias mailreplicationsecondary='sh /opt/mail-scripts/mail-replication-secondary.sh'
alias mailhelp='sh /opt/mail-scripts/mail-help.sh'
alias mailupdate='sh /opt/mail-scripts/mail-update.sh'
EOF

cat << EOF >> /opt/mail-scripts/certbot-domains.txt
mail.$DOMAIN
imap.$DOMAIN
smtp.$DOMAIN
admin.$DOMAIN

#######################
# Configure RoundCube #
#######################

echo -e "${GREEN}Install and Configure Roundcube\n${ENDCOLOR}"
sleep 1

wget -P /opt/ https://github.com/roundcube/roundcubemail/releases/download/1.6.5/roundcubemail-1.6.5-complete.tar.gz

tar xvf /opt/roundcubemail-1.6.5-complete.tar.gz -C /var/www/html
mv /var/www/html/roundcubemail-1.6.5 /var/www/html/mail

mysql --user=root --password=$SQLPASSWORD -e "CREATE DATABASE roundcubemail CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql --user=root --password=$SQLPASSWORD -e "GRANT ALL PRIVILEGES ON roundcubemail.* TO roundcube@localhost IDENTIFIED BY '$PFAPASSWORD';"
mysql --user=root --password=$SQLPASSWORD -e "FLUSH PRIVILEGES;"

chmod 777 /var/www/html/mail/temp
chmod 777 /var/www/html/mail/logs

cat << EOF >> /etc/nginx/conf.d/roundcube.conf
server {
   listen 80;
   listen [::]:80;
   server_name mail.$DOMAIN;

   root /var/www/html/mail;
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

rm -f /opt/roundcubemail-1.6.5-complete.tar.gz


#####################
# Configure CertBot #
#####################

if [[ "$CERTBOT" =~ ^([yY][eE][sS]|[yY]|[sS])$ ]]
then
echo -e "${GREEN}Configure Let's Encrypt SSL Certs\n${ENDCOLOR}"
sleep 1

if [[ "$CERTBOT" =~ ^([sS])$ ]]
then
echo -e "${GREEN}Installing Staging Certificates\n${ENDCOLOR}"
certbot run -n --nginx --agree-tos --test-cert -d mail.$DOMAIN,imap.$DOMAIN,smtp.$DOMAIN,admin.$DOMAIN -m  admin@$DOMAIN --redirect
fi

if [[ "$CERTBOT" =~ ^([yY][eE][sS]|[yY])$ ]]
then
echo -e "${GREEN}Installing Production Certificates\n${ENDCOLOR}"
certbot run -n --nginx --agree-tos -d mail.$DOMAIN,imap.$DOMAIN,smtp.$DOMAIN,admin.$DOMAIN -m  admin@$DOMAIN --redirect
fi

echo -e "${GREEN}Update Dovecot to use Let's Encypt Certificate\n${ENDCOLOR}"
#sed -i 's/ssl_cert = <\/etc\/pki\/dovecot\/certs\/dovecot.pem/ssl_cert = <\/etc\/letsencrypt\/live\/mail."$DOMAIN"\/fullchain.pem/' /etc/dovecot/conf.d/10-ssl.conf
#sed -i 's/ssl_key = <\/etc\/pki\/dovecot\/private\/dovecot.pem/ssl_key = <\/etc\/letsencrypt\/live\/mail."$DOMAIN"\/privkey.pem/' /etc/dovecot/conf.d/10-ssl.conf

sed -i 's/ssl_cert = <\/etc\/pki\/dovecot\/certs\/dovecot.pem/#ssl_cert = <\/etc\/pki\/dovecot\/certs\/dovecot.pem/' /etc/dovecot/conf.d/10-ssl.conf
sed -i 's/ssl_key = <\/etc\/pki\/dovecot\/private\/dovecot.pem/#ssl_key = <\/etc\/pki\/dovecot\/private\/dovecot.pem/' /etc/dovecot/conf.d/10-ssl.conf

cat << EOF >> /etc/dovecot/conf.d/10-ssl.conf
ssl_cert = </etc/letsencrypt/live/mail.$DOMAIN/fullchain.pem
ssl_key = </etc/letsencrypt/live/mail.$DOMAIN/privkey.pem
EOF

echo -e "${GREEN}Update Postfix to use Let's Encypt Certificate\n${ENDCOLOR}"
sed -i 's/smtpd_tls_cert_file = \/etc\/pki\/tls\/certs\/postfix.pem/#smtpd_tls_cert_file = \/etc\/pki\/tls\/certs\/postfix.pem/' /etc/postfix/main.cf
sed -i 's/smtpd_tls_key_file = \/etc\/pki\/tls\/private\/postfix.key/#smtpd_tls_key_file = \/etc\/pki\/tls\/private\/postfix.key/' /etc/postfix/main.cf

cat << EOF >> /etc/postfix/main.cf
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.$DOMAIN/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mail.$DOMAIN/privkey.pem
EOF

echo -e "${GREEN}Configure Crontab daily to renew SSL Cert\n${ENDCOLOR}"
cat << EOF >> /etc/crontab
0 12 * * * /usr/bin/certbot renew --quiet
EOF

echo -e "${GREEN}Restart services to load new certificate file\n${ENDCOLOR}"
systemctl restart nginx
systemctl restart postfix
systemctl restart dovecot

fi

##########
# Reboot #
##########
echo -e "${GREEN}Installation Complete!${ENDCOLOR}"
echo -e "Navigate to https://admin.$DOMAIN to complete the PostfixAdmin configuration"
echo -e "Navigate to http://mail.$DOMAIN to complete the RoundCube configuration"
echo -e "${RED}WARNING: If configuring for MySQL Replication, please complete the following commands first${ENDCOLOR}"
echo -e "Primary Node: run the command ${BOLD}mailreplicationprimary${NORMAL}"
echo -e "Secondary Node: run the command ${BOLD}mailreplicationsecondary${NORMAL}"
echo -e "For all mail commands available use ${BOLD}mailhelp${NORMAL}\n\n"

read -p "Would you like to reboot?[y/N]:" REBOOT
REBOOT="${REBOOT:=n}"
if [[ "$REBOOT" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "Rebooting to allow for Open-VM-Tools, Permissive Mode, and Alias Commands\n"
    sleep 5
    shutdown -r now
fi

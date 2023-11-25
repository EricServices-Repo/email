#!/usr/bin/env bash
# EricServic.es Email Server Configure Primary Node
#
# Sets up Primary Mail Node for MySQL Replication
#
###############################################################
# Version 1.0.1
#
# 
# 
################################################################

#################
# Define Colors #
#################
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"


echo -e "${GREEN}EricServic.es Email Server Primary Setup${ENDCOLOR}"

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

read -p "Secondary node IP Address [192.168.1.2]:" SECONDARYIPADDRESS
SECONDARYIPADDRESS="${SECONDARYIPADDRESS:=192.168.1.2}"
echo "$SECONDARYIPADDRESS"

read -p "MySQL Password [password]:" SQLPASSWORD
SQLPASSWORD="${SQLPASSWORD:=password}"
echo "$SQLPASSWORD"

read -p "MySQL Password [password]:" REPLICATIONPASSWORD
REPLICATIONPASSWORD="${REPLICATIONPASSWORD:=password}"
echo "$REPLICATIONPASSWORD"


echo -e "${GREEN}Configure MySQL Replication\n${ENDCOLOR}"
mysql --user=root --password=$SQLPASSWORD -e "CREATE USER replication@'%' identified by '$REPLICATIONPASSWORD';"
mysql --user=root --password=$SQLPASSWORD -e "GRANT REPLICATION SLAVE ON *.* TO replication@'%';"
mysql --user=root --password=$SQLPASSWORD -e "FLUSH PRIVILEGES;"
mysql --user=root --password=$SQLPASSWORD -e "FLUSH TABLES WITH READ LOCK;"
mysql --user=root --password=$SQLPASSWORD -e "UNLOCK TABLES;"

echo -e "Configure MySQL Firewall for Secondary Node\n"
firewall-cmd --new-zone=mariadb-access --permanent
firewall-cmd --zone=mariadb-access --add-source=$SECONDARYIPADDR/32 --permanent
firewall-cmd --zone=mariadb-access --add-port=3306/tcp  --permanent
firewall-cmd --reload

echo -e "Reconfigure MySQL Listening Interface\n"
sed -i "s/#bind-address=0.0.0.0/bind-address=0.0.0.0/" /etc/my.cnf.d/mariadb-server.cnf

sed -i '/\[mysqld\]/a server-id=1\nlog_bin = \/var\/log\/mysql\/mysql-bin.log\nbinlog-format=ROW' /etc/my.cnf.d/mariadb-server.cnf

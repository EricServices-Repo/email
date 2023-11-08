#!/usr/bin/env bash
#EricServic.es Email Server Install
#
#Installs Dovecot and Postfix email server
#
###############################################################
Version 1.0.1
# Installs pre-flight requirements
# Installs ericservic.es repo
# Installs Filebeat/Metricbeat
# Installs and Configures Dovecot
# Installs and Configures Postfix
################################################################

##### Variables ###############################
# KIBABA - Kibana IP Address
# ELASTICSEARCH - Elasticsearch IP Address
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

read -p "Set KIBANA [192.168.1.13]:" KIBANA
KIBANA="${KIBANA:=192.168.1.13}"
echo "$KIBANA"

read -p "Set ELASTICSEARCH [192.168.1.23]:" ELASTICSEARCH
ELASTICSEARCH="${ELASTICSEARCH:=192.168.1.23}"
echo "$ELASTICSEARCH"

###################
# End of Variables
###################


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

echo -e "${GREEN}Configure the EricServic.es Local Repository.\n${ENDCOLOR}"
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
echo -e "${GREEN}Process updates and install\n${ENDCOLOR}"
sleep 1

echo -e "run yum update\n"
yum update -y

echo -e "Install epel-release\n"
yum install epel-release -y

echo -e "Check to see if required programs are installed.\n"
yum install open-vm-tools curl nginx dovecot postfix mariadb mariadb-server filebeat metricbeat -y 


echo -e "Update Remi PHP and install PHP 8.2"
dnf -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module reset php -y
dnf module install php:remi-8.2
dnf -y install php
php -v

echo -e "Allow Ports for Email Server on Firewall\n"
firewall-cmd --permanent --add-port={25/tcp,143/tcp,465/tcp,587/tcp,993/tcp,995/tcp}

echo -e "Reload the firewall.\n"
firewall-cmd --reload

#######################################

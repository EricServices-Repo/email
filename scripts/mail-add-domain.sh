#!/usr/bin/env bash
#EricServic.es Email Server Add Domain
#
# Update Email Server to support additional domains 
#
###############################################################
Version 1.0.1
# Collect Variables
# Update postfix whitelist.db
# Update Certbot
################################################################

##### Variables ################################################
# DOMAIN - Domain to Add
# CERTBOT - Process Certbot update
################################################################

#################
# Define Colors #
#################
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"

echo -e "${GREEN}EricServic.es Email Server Domain Update${ENDCOLOR}"
echo -e "${BLUE} ______      _       _____                 _                    ${ENDCOLOR}"  
echo -e "${BLUE}|  ____|    (_)     / ____|               (_)                   ${ENDCOLOR}"
echo -e "${BLUE}| |__   _ __ _  ___| (___   ___ _ ____   ___  ___   ___  ___    ${ENDCOLOR}"
echo -e "${BLUE}|  __| | '__| |/ __|\___ \ / _ \ '__\ \ / / |/ __| / _ \/ __|   ${ENDCOLOR}"
echo -e "${BLUE}| |____| |  | | (__ ____) |  __/ |   \ V /| | (__ |  __/\__ \   ${ENDCOLOR}"
echo -e "${BLUE}|______|_|  |_|\___|_____/ \___|_|    \_/ |_|\___(_)___||___/ \n${ENDCOLOR}"


#####################
# Set all Variables #
#####################
echo -e "${GREEN}Set variables for domain update.${ENDCOLOR}"

read -p "Domain to add [domain.com]:" DOMAIN
DOMAIN="${DOMAIN:=domain.com}"
echo "$DOMAIN"

read -p "Update Certbot? [Y/n]:" CERTBOT
CERTBOT="${CERTBOT:=y}"
echo "$CERTBOT"

echo -e "${GREEN}Process whitelist update${ENDCOLOR}"
cat << EOF >> /etc/postfix/whitelist
$DOMAIN OK
EOF

postmap /etc/postfix/whitelist


echo -e "${GREEN}Collect all current domains${ENDCOLOR}"
certbot certificates

### READ IN DOMAINS FROM THE OUTPUT ABOVE

echo -e "${GREEN}Process Certbot update${ENDCOLOR}"
certbot run -n --nginx --agree-tos -d mail.$DOMAIN,imap.$DOMAIN,smtp.$DOMAIN,postfixadmin.$DOMAIN -m  admin@$DOMAIN --redirect

echo -e "${GREEN}Restart Nginx, Dovecot and Postfix${ENDCOLOR}"
systemctl restart nginx
systemctl restart dovecot
systemctl restart postfix

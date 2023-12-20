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


#####################
# Process whitelist #
#####################
echo -e "${GREEN}Process whitelist update${ENDCOLOR}"
cat << EOF >> /etc/postfix/whitelist
$DOMAIN OK
EOF

postmap /etc/postfix/whitelist

########################
# Process nginx config #
########################
cat << EOF >> /etc/nginx/conf.d/postfixadmin-$DOMAIN.conf
server {
   server_name admin.$DOMAIN;

   root /var/www/html/admin/public;
   index index.php index.html;

   access_log /var/log/nginx/postfixadmin_access.log;
   error_log /var/log/nginx/postfixadmin_error.log;

   location / {
       try_files $uri $uri/ /index.php;
   }

   location ~ ^/(.+\.php)$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
   }

    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/mail.ericembling.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/mail.ericembling.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot


}
server {
    if ($host = admin.$DOMAIN) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


   listen 80;
   listen [::]:80;
   server_name admin.$DOMAIN;
    return 404; # managed by Certbot
}
EOF

cat << EOF >> /etc/nginx/conf.d/roundcube-$DOMAIN.conf
server {
   server_name mail.$DOMAIN;

   root /var/www/html/mail;
   index index.php index.html;

   access_log /var/log/nginx/postfixadmin_access.log;
   error_log /var/log/nginx/postfixadmin_error.log;

   location / {
       try_files $uri $uri/ /index.php;
   }

   location ~ ^/(.+\.php)$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
   }

    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/mail.ericembling.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/mail.ericembling.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
server {
    if ($host = mail.$DOMAIN) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

   listen 80;
   listen [::]:80;
   server_name mail.$DOMAIN;
    return 404; # managed by Certbot
}
EOF




cat << EOF >> /opt/mail-scripts/certbot-domains.txt
mail.$DOMAIN
imap.$DOMAIN
smtp.$DOMAIN
admin.$DOMAIN
EOF


readarray -t URL < /opt/mail-scripts/certbot-domains.txt

echo -e "${GREEN}Collect all current domains${ENDCOLOR}"
certbot certificates

### READ IN DOMAINS FROM THE OUTPUT ABOVE

echo -e "${GREEN}Process Certbot update${ENDCOLOR}"
certbot run -n --nginx --agree-tos -d mail.$DOMAIN,imap.$DOMAIN,smtp.$DOMAIN,postfixadmin.$DOMAIN -m  admin@$DOMAIN --redirect

echo -e "${GREEN}Restart Nginx, Dovecot and Postfix${ENDCOLOR}"
systemctl restart nginx
systemctl restart dovecot
systemctl restart postfix

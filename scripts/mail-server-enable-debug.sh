#!/usr/bin/env bash
echo -e "${GREEN}Enabling Mail Server Debugs\n${ENDCOLOR}"
sed -i 's/#auth_verbose = no/auth_verbose = yes/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/#auth_verbose_passwords = no/auth_verbose_passwords = yes/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/#auth_debug = no/auth_debug = yes/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/#auth_debug_passwords = no/auth_debug_passwords = yes/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/#mail_debug = no/mail_debug = yes/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/#verbose_ssl = no/verbose_ssl = yes/' /etc/dovecot/conf.d/10-logging.conf

sed -i 's/debug_peer_level = 2/debug_peer_level = 6/' /etc/postfix/main.cf
sed -i "s/#debug_peer_list =.*/debug_peer_list = $DOMAIN/" /etc/postfix/main.cf
systemctl restart dovecot
systemctl restart postfix
echo -e "Navigate to /var/log/ to review Dovecot and Postfix debugs\n"

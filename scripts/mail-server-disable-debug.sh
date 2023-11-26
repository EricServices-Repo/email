#!/usr/bin/env bash
echo -e "${GREEN}Disabling Mail Server Debugs\n${ENDCOLOR}"
sed -i 's/auth_verbose = yes/#auth_verbose = no/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/auth_verbose_passwords = yes/#auth_verbose_passwords = no/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/auth_debug = yes/#auth_debug = no/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/auth_debug_passwords = yes/#auth_debug_passwords = no/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/mail_debug = yes/#mail_debug = no/' /etc/dovecot/conf.d/10-logging.conf
sed -i 's/verbose_ssl = yes/#verbose_ssl = no/' /etc/dovecot/conf.d/10-logging.conf

sed -i 's/debug_peer_level = 6/debug_peer_level = 2/' /etc/postfix/main.cf
sed -i "s/debug_peer_list =.*/#debug_peer_list = some.domain/" /etc/postfix/main.cf
systemctl restart dovecot
systemctl restart postfix
echo -e "Dovecot and Postfix debugs disabled\n"

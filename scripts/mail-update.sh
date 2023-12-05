#!/usr/bin/env bash
echo -e "Running Mail Scripts Updater"
#Update the script for next time
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-update.sh
chmod +x /opt/mail-scripts/mail-update.sh


wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-add-domain.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-replication-primary.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-replication-secondary.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-server-disable-debug.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-server-enable-debug.sh
wget -P /opt/mail-scripts https://raw.githubusercontent.com/EricServices-Repo/mail/main/scripts/mail-help.sh

chmod +x /opt/mail-scripts/mail-add-domain.sh
chmod +x /opt/mail-scripts/mail-replication-primary.sh
chmod +x /opt/mail-scripts/mail-replication-secondary.sh
chmod +x /opt/mail-scripts/mail-server-disable-debug.sh
chmod +x /opt/mail-scripts/mail-server-enable-debug.sh
chmod +x /opt/mail-scripts/mail-help.sh


cat << EOF >> ~/.bashrc
alias maildebug='sh /opt/mail-scripts/mail-server-enable-debug.sh'
alias mailundebug='sh /opt/mail-scripts/mail-server-disable-debug.sh'
alias maildomain='sh /opt/mail-scripts/mail-add-domain.sh'
alias mailreplicationprimary='sh /opt/mail-scripts/mail-replication-primary.sh'
alias mailreplicationsecondary='sh /opt/mail-scripts/mail-replication-secondary.sh'
alias mailhelp='sh /opt/mail-scripts/mail-help.sh'
alias mailupdate='sh /opt/mail-scripts/mail-update.sh'
EOF

echo -e " Mail Scripts Updated"

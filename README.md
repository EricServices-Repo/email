# EricServices-Email-Server


Script to automatically install dovecot, postfix and postfixadmin for email server

# Dependencies  
- Rocky Linux, Redhat, Fedora, or CentOS
- DNS Configuration
  - imap.domain.com
  - stmp.domain.com
  - postfixadmin.domain.com
  - MX Records
  - DMARC/SPF Records


# Installation    
## Live (Read the Code first!)  
    bash <(curl -s https://raw.githubusercontent.com/EricServices-Repo/email/main/email-server-install.sh)  
    
## Manual:  
    cd /opt  
    wget https://raw.githubusercontent.com/EricServices-Repo/email/main/email-server-install.sh
    chmod +x email-server-install.sh
    ./email-server-install.sh


# Variables    
SQLPASSWORD = Define the root mysql password  
PSAPASSWORD = Define the password mysql for postfixadmin  
KIBANA = Define the Kibana Host  
ELASTICSEARCH = Define the Elasticsearch Node  
ESREPO = EricServic.es Rocky Linux Repository  


# Post Installation    
Will need to complete the postfixadmin install via web
-postfixadmin.domain.com or http://<IP-ADDR>/postfixadmin/public


# Customization    
Toggle EricServic.es Repository usage    


# Support    
[Discord](https://discord.gg/8nKBgURRbW)


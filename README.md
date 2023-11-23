# EricServices-Email-Server


Script to automatically install dovecot, postfix and postfixadmin for email server

# Dependencies  
- Rocky Linux, Redhat, Fedora, or CentOS
- DNS Configuration
  - mail.domain.com
  - imap.domain.com
  - smtp.domain.com
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
SQLPASSWORD = Define the root user password for mysql  
PFAPASSWORD = Define the postfixadmin user password for mysql  
ESREPO = EricServic.es Rocky Linux Repository  
CERTBOT = Toggle to enable Certbot install  


# Post Installation    
Will need to complete the postfixadmin install via web  
postfixadmin.domain.com or IP-ADDR/postfixadmin/public  

# Debug Commands 
debugmial - Sets the logging level higher for Dovecot and Postfix logs in /var/log  
undebugmail - Sets the logging level back to original level  

# Customization    
Toggle EricServic.es Repository usage  
Toggle CertBot to load certificates  
Toggle CertBot to use Staging Server (no rate limit for development)  


# Support    
[Discord](https://discord.gg/8nKBgURRbW)


#!/usr/bin/env bash
echo -e "Set variables for domain update."

#Create Swap file
fallocate -l 1G /swapfile

#Change Permissions
chmod 600 /swapfile

#Mark as Swap
mkswap /swapfile

# Enable Swap
swapon /swapfile

#Make Swap permanent
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

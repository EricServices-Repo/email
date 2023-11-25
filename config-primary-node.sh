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

read -p "Use EricServic.es Repository [y/N]:" ESREPO
ESREPO="${ESREPO:=n}"
echo "$ESREPO"







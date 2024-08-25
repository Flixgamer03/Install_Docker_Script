#!/usr/bin/env bash

# +----- Variables ---------------------------------------------------------+

datetime="$(date "+%Y-%m-%d-%H-%M-%S")"
cdir=$(pwd)
logfile="/tmp/prepare_RHEL_${datetime}.log"
width=80

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)
YN="(Yes|${BRIGHT}No${NORMAL}) >> "

# +----- Functions ---------------------------------------------------------+

echo_Right() {
    text=${1}
    echo
    tput cuu1
    tput cuf "$((${width} - 1))"
    tput cub ${#text}
    echo "${text}"
}

echo_Done() {
    tput setaf 2 0 0
    echo_Right "[ Done ]"
    tput sgr0
}

echo_Skipped() {
    tput setaf 3 0 0
    echo_Right "[ Skipped ]"
    tput sgr0
}

echo_Failed() {
    tput setaf 1 0 0
    echo_Right "[ Failed ]"
    tput sgr0
}

get_User() {
    if ! [[ $(id -u) = 0 ]]; then
        echo -e  "\n ${RED}[ Error ]${NORMAL} This script must be run as root.\n" 
        exit 1
    fi
}

antwoord() {
    read -p "${1}" antwoord
        if [[ ${antwoord} == [yY] || ${antwoord} == [yY][Ee][Ss] ]]; then
            echo "yes"
        else
            echo "no"
        fi
}

display_Notice() {
    clear
    tput setaf 6
    #cat ${cdir}/notice.txt
    tput sgr0
    proceed="$(antwoord "Do you want to proceed? ${YN}")"
}

DNFPluginsCore_query() {
    InstallDNFPluginsCore="$(antwoord "Do you want to get dnf-plugins-core installed? ${YN}")"
}

DNFPluginsCore_install() {
    echo -n -e "Installing dnf-plugins-core\r"
    if [[ "${InstallDNFPluginsCore}" = "yes" ]]; then
        dnf install -y dnf-plugins-core >> ${logfile} 2>&1
        echo_Done
    else
        echo_Skipped
    fi
}

DockerRepo_Add() {
    echo -n -e "Adding Docker Repo\r"
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >> ${logfile} 2>&1
    echo_Done
}

Docker_install() {
    echo -n -e "Installing Docker\r"
    yes | dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> ${logfile} 2>&1
    echo_Done
}

DockerStart_query() {
    StartDocker="$(antwoord "Do you want to start Docker? ${YN}")"
}

Docker_start() {
    echo -n -e "Starting Docker\r"
    if [[ "${StartDocker}" = "yes" ]]; then
        systemctl start docker >> ${logfile} 2>&1
        if [[ "$(systemctl is-active docker)" = "active" ]]; then
            echo_Done
        else
            echo_Failed
        fi
    else
        echo_Skipped
    fi
}

DockerEnable_query() {
    EnableDocker="$(antwoord "Do you want to get docker startet automatically? ${YN}")"
}

Docker_enable() {
    echo -n -e "Enabling Docker to start automatically\r"
    if [[ "${EnableDocker}" = "yes" ]]; then
        systemctl enable docker >> ${logfile} 2>&1
        if [[ "$(systemctl is-enabled docker)" = "enabled" ]]; then
            echo_Done
        else
            echo_Failed
        fi
    else
        echo_Skipped
    fi
}

# +----- Main --------------------------------------------------------------+
get_User
display_Notice
if [[ "${proceed}" = "no" ]]; then
    exit 1
fi

# Queries
DNFPluginsCore_query
DockerStart_query
DockerEnable_query
# Functions
DNFPluginsCore_install
DockerRepo_Add
Docker_install
Docker_start
Docker_enable

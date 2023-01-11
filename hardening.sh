#!/usr/bin/env bash

# COLOR FORE
RED='\e[91m'
BLUE='\e[94m'
YELLOW='\e[93m'
GREEN='\e[92m'
NC='\e[39m'

function banner() {
    clear

    echo "---[ LINUX HARDENING ]---"
    echo ""
    echo "Based on : https://github.com/trimstray/linux-hardening-checklist"
}

function requirements() {
    _packages_requirements=(sed awk wc lsblk)

    for i in ${!_packages_requirements[@]}; do
        
        WHICH=$(which ${_packages_requirements[${i}]} 2>/dev/null)
        if [ $? != 0 ]; then
            echo "  package ${_packages_requirements[${i}]} missing"
            exit 1 
        else
            if [[ ${VERBOSE} == "True" ]]; then
                echo "  ${_packages_requirements[${i}]} : ok"
            fi
        fi
    done
}

function verbose_output() {
    STATUS=$1
    MESSAGE=$2

    if [[ ${VERBOSE} == "True" ]]; then
        if [[ ${STATUS} == "NOK" ]]; then
            echo -e "${RED}[FAIL]${NC} ${MESSAGE}"
        else
            echo -e "${GREEN}[PASS]${NC} ${MESSAGE}"
        fi
    fi
}

function _conformity() {
    CONFORMITY=$(expr ${CONFORMITY} + $1)
}

###
# SCANNERS
###

function separate_partitions() {
    local FOLDER="/$1"
    local FOLDER_SED="\/$1"
    local REQUIRED=$2
    
    local BOOT_PARTITION="$(lsblk | sed -En "/.*?part\s*${FOLDER_SED}/p")"
    if [[ -z ${BOOT_PARTITION} ]]; then
        verbose_output "NOK" "${FOLDER} not in a separate partition"
        _conformity "0"
    else
        verbose_output "OK" "${FOLDER} is in a separate partition"
        _conformity "1"
    fi
}

function restrict_mount_options() {
    # Multiple sub folder filter
    if [[ *$1* == *"/"* ]]; then
        local FOLDER_SED=$(sed 's/\//\\\//g' $1 2>/dev/null)
    else
        local FOLDER_SED="\/$1"
    fi

    local FOLDER="/$1"
    local OPTIONS=($2)

    local FSTAB_PATH="/etc/fstab"

    local MOUNT_POINT_SET="False"
    local FSTAB_FOLDER=($(sed -En "/^\s*UUID.*?${FOLDER_SED}/p" ${FSTAB_PATH} | awk -F' ' '{print $2}'))
    for mount_point in ${FSTAB_FOLDER[@]}; do
        if [[ ${mount_point} == ${FOLDER} ]]; then
            MOUNT_POINT_SET="True"
        fi
    done

    if [[ -z ${FSTAB_FOLDER} || ${MOUNT_POINT_SET} == "False" ]]; then
        verbose_output "NOK" "${FOLDER} not restricted"
        _conformity "0"
    else
        FSTAB_OPTION=$(sed -En "/^\s*UUID.*?$FOLDER_SED\s*/p" ${FSTAB_PATH} | awk -F' ' '{print $4}')
        local FSTAB_LIST=($(echo ${FSTAB_OPTION} | sed 's/,/ /g'))
        for option in ${OPTIONS[@]}; do
            OPTIONS_OK="False"
            for fstab_option in ${FSTAB_LIST[@]}; do
                if [[ ${option} == ${fstab_option} ]]; then
                    OPTIONS_OK="True"
                fi
            done

            if [[ ${OPTIONS_OK} == "False" ]]; then
                verbose_output "NOK" "${option} in ${FOLDER} missing"
                _conformity "0"
            else
                verbose_output "OK" "${option} restrict ${FOLDER}"
                _conformity "1"
            fi
        done
    fi
}

function disk_encrypted() {
    local DISKS_ENCRYPTED=$(sed -En '/^\s*.*?UUID.*?/p' /etc/crypttab)
    local DISKS_ENCRYPTED_NAME=$(echo ${DISKS_ENCRYPTED} | awk -F' ' '{print $1}')
    if [[ -z ${DISKS_ENCRYPTED} ]]; then
        verbose_output "NOK" "${DISKS_ENCRYPTED_NAME} is not encrypted"
        _conformity "0"
    else
        verbose_output "OK" "${DISKS_ENCRYPTED_NAME} is encrypted"
        _conformity "1"
    fi
}

###
# LEVELS
###

function level_low() {
    # separate partition
    separate_partitions 'boot' "yes"
    separate_partitions 'home' "yes"
    separate_partitions 'usr' "yes"

    # Restrict mount option
    restrict_mount_options "usr" "default nodev ro"
    restrict_mount_options "var" "default nosuid"
    restrict_mount_options "var/log" "defaults nosuid noexec nodev"
    restrict_mount_options "var/log/audit" "defaults nosuid noexec nodev"
    restrict_mount_options "proc" "defaults hidepid=2"

    # Disk encrypted
    disk_encrypted
}

###
# START
###

function main() {
    banner

    if [[ ${VERBOSE} == "True" ]]; then
        echo "system dependences : "
    fi
    requirements

    # Conformity score init
    CONFORMITY=0

    # Level selector
    case ${LEVEL_SELECTED} in 
        default)
            level_low
            ;;
        low)
            level_low
            ;;
        medium)
            ;;
        hard)
            ;;
    esac

    echo "${CONFORMITY}/20"
}


while [ $# -gt 0 ]; do
    case $1 in
        -l|--level)
            LEVEL_SELECTED="${2}"
            if [[ -z ${LEVEL_SELECTED} ]]; then
                LEVEL_SELECTED="default"
            fi
            ;;
        -v|--verbose)
            VERBOSE="True"
        ;;
        -h|--help)
            ;;
    esac
    shift
done

main
#!/bin/bash

# COLOR FORE
RED='\e[91m'
BLUE='\e[94m'
YELLOW='\e[93m'
GREEN='\e[92m'
NC='\e[39m'

CONFORMITY="0"

function level_low() {
    local BOOT_PARTITION="$(lsblk | sed -En '/.*?part\s*\/boot/p')"
    if [[ -z ${BOOT_PARTITION} ]]; then
        echo -e "${RED}[!]${NC} /boot not in the separate partition"
    else
        echo -e "${GREEN}[+]${NC} /boot in the separate file"
        CONFORMITY="$(expr ${CONFORMITY}+1)"
    fi

    local HOME_PARTITION="$(lsblk | sed -En '/.*?part\s*\/home/p')"
    if [[ -z ${HOME_PARTITION} ]]; then
        echo -e "${RED}[!]${NC} /home not in the separate partition"
    else
        echo -e "${GREEN}[+]${NC} /home in the separate file"
        CONFORMITY="$(expr ${CONFORMITY}+1)"
    fi

    local USR_PARTITION="$(lsblk | sed -En '/.*?part\s*\/usr/p')"
    if [[ -z ${USR_PARTITION} ]]; then
        echo -e "${RED}[!]${NC} /usr not in the separate partition"
    else
        echo -e "${GREEN}[+]${NC} /usr in the separate file"
        CONFORMITY="$(expr ${CONFORMITY}+1)"
    fi

    RESTRICT_USR="$(sed -En '/^\s*UUID.*?\/usr/p' .test/fstab | awk -F' ' '{print $4}')"
    if [[ -z ${RESTRICT_USR} ]]; then
        echo -e "${RED}[!]${NC} /usr not restricted"
    else
        RESTRICT_USR_NUMBER="$(echo ${RESTRICT_USR} | sed 's/,/\n/g' | wc -l)"
        for i in $(seq 1 ${RESTRICT_USR_NUMBER}); do
            RESTRICT_USR_ARG_CURRENT="$(echo ${RESTRICT_USR} | sed 's/,/\n/g' | sed -n ${i}p)"
            if [[ ${RESTRICT_USR_ARG_CURRENT} == "defaults" ]]; then
                RESTRICT_USR_ARG_DEFAULTS="1"
            elif [[ ${RESTRICT_USR_ARG_CURRENT} == "nodev" ]]; then
                RESTRICT_USR_ARG_NODEV="1"
            elif [[ ${RESTRICT_USR_ARG_CURRENT} == "ro" ]]; then
                RESTRICT_USR_ARG_RO="1"
            fi
        done

        if [[ ${RESTRICT_USR_ARG_DEFAULTS} == "1" && ${RESTRICT_USR_ARG_NODEV} == "1" && ${RESTRICT_USR_ARG_RO} == "1" ]]; then
            echo -e "${GREEN}[+]${NC} /usr correctly restricted"
            CONFORMITY="$(expr ${CONFORMITY}+1)"
        else
        echo -e "${RED}/usr${NC}"
            if [[ ${RESTRICT_USR_ARG_DEFAULTS} != "1" ]]; then
                echo -e "  ➥ ${RED}default${NC} missing"
            fi
            
            if [[ ${RESTRICT_USR_ARG_NODEV} != "1" ]]; then
                echo -e "  ➥ ${RED}nodev${NC} missing"
            fi
            
            if [[ ${RESTRICT_USR_ARG_RO} != "1" ]]; then
                echo -e "  ➥ ${RED}ro${NC} missing"
            fi
        fi
    fi
}

function main() {
    clear
    echo -e "LINUX HARDENING"
    echo -e "Based on : https://github.com/trimstray/linux-hardening-checklist"

    if [[ ${LEVEL_SELECTED} == "default" ]]; then
        level_low

    elif [[ ${LEVEL_SELECTED} == "low" ]]; then
        level_low

        if [[ ${CONFORMITY} > "10" ]];then
            echo -e "Conformity level : ${GREEN}${CONFORMITY}${NC}/20"
        fi
    fi

}

while [ $# -gt 0 ]; do
    case $1 in
        -l|--level)
            LEVEL_SELECTED="${2}"
            if [[ -z ${LEVEL_SELECTED} ]]; then
                LEVEL_SELECTED="default"
            fi
            ;;
        -h|--help)
            ;;
    esac
    shift
done

main

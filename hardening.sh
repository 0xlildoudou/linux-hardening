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

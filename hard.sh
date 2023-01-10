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

###
# SCANNERS
###

function separate_partitions() {
    FOLDER="$1"
    FOLDER_SED="\/$1"
    REQUIRED=$2
    local BOOT_PARTITION="$(lsblk | sed -En "/.*?part\s*${FOLDER_SED}/p")"
    if [[ -z ${BOOT_PARTITION} ]]; then
        verbose_output "NOK" "${FOLDER} not in a separate partition"
    else
        verbose_output "OK" "${FOLDER} is in a separate partition"
    fi
}

###
# LEVELS
###

function level_low() {
    # /home separate partition
    separate_partitions 'home' "yes"
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
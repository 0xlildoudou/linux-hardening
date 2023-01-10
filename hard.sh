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
    _packages_requirements=(sed awk wc)

    for i in ${!_packages_requirements[@]}; do
        
        WHICH=$(which ${_packages_requirements[${i}]} 2>/dev/null)
        if [ $? != 0 ]; then
            echo "  package ${_packages_requirements[${i}]} missing"
        else
            echo "  ${_packages_requirements[${i}]} : ok"
        fi
    done
}

###
# SCANNERS
###

function separate_partitions() {
    FOLDER=$1
    REQUIRED=$2
}

###
# LEVELS
###

function level_low() {
    # /home separate partition
    separate_partitions "/home" "yes"
}

###
# START
###

function main() {
    banner

    if [[ ${VERBOSE} == "True" ]]; then
        echo "system dependences : "
        requirements
    fi

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
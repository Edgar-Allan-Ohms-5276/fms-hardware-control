#!/bin/sh

DIR=$(dirname "$0")

. $DIR/global.sh

__usage="
    This script adopts all available hardware from UniFi controller 

    Usage: 02-ADOPT-ALL-HARDWARE.sh [true | false]

    Parameters:
        0th:
            - true: Wait for all hardware items to be in ready state.
            - false: Only attempt adoption, then exit.

    Exit codes:
        0  - Success
        1  - Nonspecific runtime error
        11 - Login information incorrect
        12 - Ready wait timed out
    
    Requires:
        - curl
        - jq
"

entrypoint() {
    if [ $# -ne 1 ] || [ $1 = "help" ]; then
        show_usage
    fi

    : ${CONTROLLER_PASSWORD:?"Controller password not set"}

    case "$1" in
        true|false)
            ;;
        *)
            show_usage "0th param can only be one of [true, false]"
            ;;
    esac

    # Ready to run

    COOKIEFILE=`. $DIR/resources/controller-login.sh`
    LOGIN_SUCCESS=$?
    trap "rm -f $COOKIEFILE" 0 2 3 1
    if [ $LOGIN_SUCCESS -ne 0 ]; then
        echo "Login failure"
        return 11
    fi
    DEVICEDATA=`curl -b "$COOKIEFILE" -k -s https://fms.nevermore:8443/api/s/default/stat/device-basic | jq '.data'`
    NUM_OF_DEVICES=`echo $DEVICEDATA | jq '. | length'`
    for i in `seq 0 $(expr $NUM_OF_DEVICES - 1)`; do #For each device
        DEVICE=`echo $DEVICEDATA | jq --argjson i $i '.[$i]'`
        if [ `echo $DEVICE | jq '.adopted'` = "false" ]; then 
            DATA=`echo $DEVICE | jq '{ "mac": .mac, "cmd": "adopt" }'`
            echo Beginning adoption of `echo $DEVICE | jq -r '.type'`-`echo $DEVICE | jq -r '.model'`
            curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X POST -k -s https://fms.nevermore:8443/api/s/default/cmd/devmgr > /dev/null
        fi
    done

    if [ $1 = "true" ]; then
        . $DIR/resources/wait-for-unifi-ready.sh
        WAIT_STATUS=$?
        if [ $WAIT_STATUS -ne 0 ]; then
            return 12
        fi
    fi

}



entrypoint "$@"
exit $?
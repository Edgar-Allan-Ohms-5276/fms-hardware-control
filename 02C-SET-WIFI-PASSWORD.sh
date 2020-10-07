#!/bin/sh

DIR=$(dirname "$0")

. $DIR/global.sh

__usage="
    This script configures the WIFI password for the ADM ans SAL WIFI networks. 

    Usage: 02C-SET-WIFI-PASSWORD.sh PASSWORD [true|false]

    Parameters:
        0th: A valid WPA key (password)
        1st:
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
    if [ $# -ne 2 ] || [ $1 = "help" ]; then
        show_usage
    fi

    : ${CONTROLLER_PASSWORD:?"Controller password not set"}

    case "$2" in
        true|false)
            ;;
        *)
            show_usage "1st param can only be one of [true, false]"
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

    get_globals

    DATA=`jq -n --arg PASSWORD $1 '{"x_passphrase":$PASSWORD}'`
    curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X PUT -k -s https://fms.nevermore:8443/api/s/default/rest/wlanconf/$ADM_ID > /dev/null
    curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X PUT -k -s https://fms.nevermore:8443/api/s/default/rest/wlanconf/$SAL_ID > /dev/null

    if [ $2 = "true" ]; then
        . $DIR/resources/wait-for-unifi-ready.sh
        WAIT_STATUS=$?
        if [ $WAIT_STATUS -ne 0 ]; then
            return 12
        fi
    fi

}

get_globals() {
    ADM_ID="unset"
    SAL_ID="unset"

    WLANDATA=`curl -b "$COOKIEFILE" -k -s https://fms.nevermore:8443/api/s/default/rest/wlanconf | jq '.data'`
    NUM_OF_WLANS=`echo $WLANDATA | jq '. | length'`
    for i in `seq 0 $(expr $NUM_OF_WLANS - 1)`; do #For each wlan
        WLAN=`echo $WLANDATA | jq --argjson i $i '.[$i]'`
        WLAN_ID=`echo $WLAN | jq -r ._id`
        if [ "`echo $WLAN | jq -r .name`" = "Nevermore-SAL" ]; then
             SAL_ID=$WLAN_ID
        fi
        if [ "`echo $WLAN | jq -r .name`" = "Nevermore-ADM" ]; then
             ADM_ID=$WLAN_ID
        fi
    done
}



entrypoint "$@"
exit $?
#!/bin/sh

DIR=$(dirname "$0")

. $DIR/global.sh

__usage="
    This script configures all available hardware from UniFi controller 

    Usage: 02A-SET-PASSWORD.sh PASSWORD

    Parameters:
        0th: The new password to set

    Exit codes:
        0  - Success
        1  - Nonspecific runtime error
        11 - Login information incorrect
    
    Requires:
        - curl
        - jq
"

entrypoint() {
    if [ $# -ne 1 ] || [ $1 = "help" ]; then
        show_usage
    fi

    : ${CONTROLLER_PASSWORD:?"Controller password not set"}

    if [ -z "$1" ]; then
        show_usage "0th param is required"
    fi
    NEW_PASSWORD=$1

    # Ready to run

    COOKIEFILE=`. $DIR/resources/controller-login.sh`
    LOGIN_SUCCESS=$?
    trap "rm -f $COOKIEFILE" 0 2 3 1
    if [ $LOGIN_SUCCESS -ne 0 ]; then
        echo "Login failure"
        return 11
    fi

    DATA=`jq -n --arg OLD_PASSWORD $CONTROLLER_PASSWORD --arg NEW_PASSWORD $NEW_PASSWORD '{"x_oldpassword": $OLD_PASSWORD, "x_password": $NEW_PASSWORD}'`
    curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X PUT -k -s https://fms.nevermore:8443/api/self > /dev/null
    echo "Password changed"


}



entrypoint "$@"
exit $?
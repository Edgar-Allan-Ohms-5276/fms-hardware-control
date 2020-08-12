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

    . $DIR/resources/controller-login.sh

}



entrypoint "$@"
exit $?
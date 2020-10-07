#!/bin/sh

DIR=$(dirname "$0")

. $DIR/global.sh

__usage="
    This script configures the WIFI networks for teams. 

    Usage: 02C-SET-WIFI-PASSWORD.sh RED1SSID RED1PWD RED2SSID RED2PWD RED3SSID RED3PWD BLUE1SSID BLUE1PWD BLUE2SSID BLUE2PWD BLUE3SSID BLUE3PWD [true|false]

    Parameters:
        0th, 2nd, 4th, 6th, 8th, 10th: A valid SSID
        1st, 3rd, 5th, 7th, 9th, 12th: A valid WPA Key (Password)
        12th:
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
    if [ $# -ne 13 ] || [ $1 = "help" ]; then
        show_usage
    fi

    : ${CONTROLLER_PASSWORD:?"Controller password not set"}

    case "${13}" in
        true|false)
            ;;
        *)
            show_usage "12th param can only be one of [true, false]"
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

    WLANDATA=`curl -b "$COOKIEFILE" -k -s https://fms.nevermore:8443/api/s/default/rest/wlanconf | jq '.data'`
    NUM_OF_WLANS=`echo $WLANDATA | jq '. | length'`
    for i in `seq 0 $(expr $NUM_OF_WLANS - 1)`; do #For each wlan
        WLAN=`echo $WLANDATA | jq --argjson i $i '.[$i]'`
        WLAN_ID=`echo $WLAN | jq -r ._id`
        if [ `echo $WLAN | jq -r .wlangroup_id` = $FIELD_ID ]; then
            curl -b "$COOKIEFILE" -H 'Content-Type: application/json' -X DELETE -k -s https://fms.nevermore:8443/api/s/default/rest/wlanconf/$WLAN_ID > /dev/null
        fi
    done

    create_ssid ${1} ${2} 11
    create_ssid ${3} ${4} 12
    create_ssid ${5} ${6} 13
    create_ssid ${7} ${8} 21
    create_ssid ${9} ${10} 22
    create_ssid ${11} ${12} 23

    if [ $13 = "true" ]; then
        . $DIR/resources/wait-for-unifi-ready.sh
        WAIT_STATUS=$?
        if [ $WAIT_STATUS -ne 0 ]; then
            return 12
        fi
    fi

}

get_globals() {
    FIELD_ID="unset"

    WLANGDATA=`curl -b "$COOKIEFILE" -k -s https://fms.nevermore:8443/api/s/default/rest/wlangroup | jq '.data'`
    NUM_OF_WLANGS=`echo $WLANGDATA | jq '. | length'`
    for i in `seq 0 $(expr $NUM_OF_WLANGS - 1)`; do #For each wlan
        WLANG=`echo $WLANGDATA | jq --argjson i $i '.[$i]'`
        WLANG_ID=`echo $WLANG | jq -r ._id`
        if [ "`echo $WLANG | jq -r .name`" = "Field" ]; then
             FIELD_ID=$WLANG_ID
        fi
    done
}

# $1: SSID, $2: WPA, $3: VLAN
create_ssid() {
        DATA='''
{
   "bc_filter_enabled":false,
   "dtim_mode":"default",
   "group_rekey":3600,
   "mac_filter_enabled":false,
   "minrate_ng_enabled":false,
   "minrate_ng_data_rate_kbps":1000,
   "minrate_ng_advertising_rates":false,
   "minrate_ng_cck_rates_enabled":true,
   "minrate_ng_beacon_rate_kbps":1000,
   "minrate_ng_mgmt_rate_kbps":1000,
   "minrate_na_enabled":false,
   "minrate_na_data_rate_kbps":6000,
   "minrate_na_advertising_rates":false,
   "minrate_na_beacon_rate_kbps":6000,
   "minrate_na_mgmt_rate_kbps":6000,
   "security":"wpapsk",
   "wpa_mode":"wpa2",
   "name":$SSID,
   "enabled":true,
   "mcastenhance_enabled":false,
   "fast_roaming_enabled":false,
   "vlan_enabled":true,
   "vlan":$VLAN,
   "hide_ssid":true,
   "x_passphrase":$WPA,
   "is_guest":false,
   "uapsd_enabled":false,
   "name_combine_enabled":true,
   "name_combine_suffix":"",
   "no2ghz_oui":false,
   "radius_mac_auth_enabled":false,
   "radius_macacl_format":"none_lower",
   "radius_macacl_empty_password":false,
   "wlangroup_id":$FIELD_ID,
   "radius_das_enabled":false,
   "wpa_enc":"ccmp"
}
'''
    DATA=`jq -n --arg SSID $1 --arg WPA $2 --arg VLAN $3 --arg FIELD_ID $FIELD_ID "$DATA"`
    curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X POST -k -s https://fms.nevermore:8443/api/s/default/rest/wlanconf > /dev/null
}



entrypoint "$@"
exit $?
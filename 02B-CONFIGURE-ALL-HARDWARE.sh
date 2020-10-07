#!/bin/sh

DIR=$(dirname "$0")

. $DIR/global.sh

__usage="
    This script configures all available hardware from UniFi controller 

    Usage: 02B-CONFIGURE-ALL-HARDWARE.sh [true | false]

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

    get_globals

    DEVICEDATA=`curl -b "$COOKIEFILE" -k -s https://fms.nevermore:8443/api/s/default/stat/device | jq '.data'`
    NUM_OF_DEVICES=`echo $DEVICEDATA | jq '. | length'`
    for i in `seq 0 $(expr $NUM_OF_DEVICES - 1)`; do #For each device
        DEVICE=`echo $DEVICEDATA | jq --argjson i $i '.[$i]'`
        if [ `echo $DEVICE | jq -r .model` = "US8P150" ]; then
            configure_root_switch `echo $DEVICE | jq -r ._id`

            ROOT_DOWNLINKS=`echo $DEVICE | jq .downlink_table`
            NUM_OF_DOWNLINKS=`echo $ROOT_DOWNLINKS | jq '. | length'`
            for d in `seq 0 $(expr $NUM_OF_DOWNLINKS - 1)`; do #For each downlink
                DOWNLINK=`echo $ROOT_DOWNLINKS | jq --argjson d $d '.[$d]'` 
                DOWNLINK_DEVICE_ID="unset"
                for j in `seq 0 $(expr $NUM_OF_DEVICES - 1)`; do #For each device
                    DOWNLINK_DEVICE=`echo $DEVICEDATA | jq --argjson j $j '.[$j]'`
                    if [ `echo $DOWNLINK_DEVICE | jq .mac` = `echo $DOWNLINK | jq .mac` ]; then
                        DOWNLINK_DEVICE_ID=`echo $DOWNLINK_DEVICE | jq -r ._id`
                    fi
                done
                if [ $DOWNLINK_DEVICE_ID = "unset" ]; then
                    continue
                fi
                if [ `echo $DOWNLINK | jq .port_idx` -eq 7 ]; then
                    #Red Flex Mini
                    configure_red_side_switch $DOWNLINK_DEVICE_ID
                fi
                if [ `echo $DOWNLINK | jq .port_idx` -eq 8 ]; then
                    #Blue Flex Mini
                    configure_blue_side_switch $DOWNLINK_DEVICE_ID
                fi
                if [ `echo $DOWNLINK | jq .port_idx` -eq 6 ]; then
                    #WIFI AP
                    configure_ap $DOWNLINK_DEVICE_ID
                fi
            done
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

get_globals() {
    BLUE_SIDE_PORTCONF_ID="unset"
    RED_SIDE_PORTCONF_ID="unset"
    ALL_PORTCONF_ID="unset"
    DISABLED_PORTCONF_ID="unset"
    RED1_PORTCONF_ID="unset"
    RED2_PORTCONF_ID="unset"
    RED3_PORTCONF_ID="unset"
    BLUE1_PORTCONF_ID="unset"
    BLUE2_PORTCONF_ID="unset"
    BLUE3_PORTCONF_ID="unset"
    ADM_PORTCONF_ID="unset"

    FIELD_WLAN_ID="unset"
    EXTERNAL_WLAN_ID="unset"

    PORTCONFDATA=`curl -b "$COOKIEFILE" -k -s https://fms.nevermore:8443/api/s/default/rest/portconf | jq '.data'`
    NUM_OF_PORTCONFS=`echo $PORTCONFDATA | jq '. | length'`
    for i in `seq 0 $(expr $NUM_OF_PORTCONFS - 1)`; do #For each portconf
        PORTCONF=`echo $PORTCONFDATA | jq --argjson i $i '.[$i]'`
        PORTCONF_ID=`echo $PORTCONF | jq -r ._id`
        if [ "`echo $PORTCONF | jq -r .name`" = "Red Side" ]; then
            RED_SIDE_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "Blue Side" ]; then
            BLUE_SIDE_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "All" ]; then
            ALL_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "Disabled" ]; then
            DISABLED_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "RED1" ]; then
            RED1_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "RED2" ]; then
            RED2_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "RED3" ]; then
            RED3_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "BLUE1" ]; then
            BLUE1_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "BLUE2" ]; then
            BLUE2_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "BLUE3" ]; then
            BLUE3_PORTCONF_ID=$PORTCONF_ID
        fi
        if [ "`echo $PORTCONF | jq -r .name`" = "Administration" ]; then
            ADM_PORTCONF_ID=$PORTCONF_ID
        fi
    done

    WLANDATA=`curl -b "$COOKIEFILE" -k -s https://fms.nevermore:8443/api/s/default/rest/wlangroup | jq '.data'`
    NUM_OF_WLANS=`echo $WLANDATA | jq '. | length'`
    for i in `seq 0 $(expr $NUM_OF_WLANS - 1)`; do #For each wlan
        WLAN=`echo $WLANDATA | jq --argjson i $i '.[$i]'`
        WLAN_ID=`echo $WLAN | jq -r ._id`
        if [ "`echo $WLAN | jq -r .name`" = "External" ]; then
             EXTERNAL_WLAN_ID=$WLAN_ID
        fi
        if [ "`echo $WLAN | jq -r .name`" = "Field" ]; then
             FIELD_WLAN_ID=$WLAN_ID
        fi
    done
}

# $1: _id
configure_root_switch() {
    DATA='''
{
   "port_overrides":[
      {
         "port_idx":1,
         "portconf_id": $ALL_PORTCONF_ID,
         "poe_mode":"auto",
         "name":"Router Trunk"
      },
      {
         "port_idx":2,
         "portconf_id": $ALL_PORTCONF_ID,
         "poe_mode":"auto",
         "name":"FMS Trunk"
      },
      {
         "port_idx":3,
         "portconf_id": $ADM_PORTCONF_ID,
         "poe_mode":"auto",
         "name":"Administration 1"
      },
      {
         "port_idx":4,
         "portconf_id": $DISABLED_PORTCONF_ID,
         "poe_mode":"off",
      },
      {
         "port_idx":5,
         "portconf_id": $DISABLED_PORTCONF_ID,
         "poe_mode":"off",
      },
      {
         "port_idx":6,
         "portconf_id": $ALL_PORTCONF_ID,
         "poe_mode":"auto",
         "name":"WIFI AP Trunk"
      },
      {
         "port_idx":7,
         "portconf_id": $RED_SIDE_PORTCONF_ID,
         "poe_mode":"auto",
         "name":"Red Side"
      },
      {
         "name":"Blue Side",
         "port_idx":8,
         "portconf_id": $BLUE_SIDE_PORTCONF_ID,
         "poe_mode":"auto"
      }
   ]
}
'''
    DATA=`jq -n --arg ALL_PORTCONF_ID $ALL_PORTCONF_ID --arg DISABLED_PORTCONF_ID $DISABLED_PORTCONF_ID --arg ADM_PORTCONF_ID $ADM_PORTCONF_ID --arg RED_SIDE_PORTCONF_ID $RED_SIDE_PORTCONF_ID --arg BLUE_SIDE_PORTCONF_ID $BLUE_SIDE_PORTCONF_ID "$DATA"`
    curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X PUT -k -s https://fms.nevermore:8443/api/s/default/rest/device/$1 > /dev/null
}

# $1: _id
configure_red_side_switch() {
    DATA='''
{
   "port_overrides":[
      {
         "port_idx":1,
         "portconf_id":$ALL_PORTCONF_ID,
         "name":"Trunk"
      },
      {
         "port_idx":2,
         "portconf_id":$RED1_PORTCONF_ID,
         "name":"RED1"
      },
      {
         "name":"RED2",
         "port_idx":3,
         "portconf_id":$RED2_PORTCONF_ID,
      },
      {
         "name":"RED3",
         "port_idx":4,
         "portconf_id":$RED3_PORTCONF_ID
      },
      {
         "port_idx":5,
         "portconf_id":$DISABLED_PORTCONF_ID
      }
   ]
}
'''
    DATA=`jq -n --arg ALL_PORTCONF_ID $ALL_PORTCONF_ID --arg DISABLED_PORTCONF_ID $DISABLED_PORTCONF_ID --arg RED1_PORTCONF_ID $RED1_PORTCONF_ID --arg RED2_PORTCONF_ID $RED2_PORTCONF_ID --arg RED3_PORTCONF_ID $RED3_PORTCONF_ID "$DATA"`
    curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X PUT -k -s https://fms.nevermore:8443/api/s/default/rest/device/$1 > /dev/null
}

# $1: _id
configure_blue_side_switch() {
    DATA='''
{
   "port_overrides":[
      {
         "port_idx":1,
         "portconf_id":$ALL_PORTCONF_ID,
         "name":"Trunk"
      },
      {
         "port_idx":2,
         "portconf_id":$BLUE1_PORTCONF_ID,
         "name":"BLUE1"
      },
      {
         "name":"BLUE2",
         "port_idx":3,
         "portconf_id":$BLUE2_PORTCONF_ID,
      },
      {
         "name":"BLUE3",
         "port_idx":4,
         "portconf_id":$BLUE3_PORTCONF_ID
      },
      {
         "port_idx":5,
         "portconf_id":$DISABLED_PORTCONF_ID
      }
   ]
}
'''
    DATA=`jq -n --arg ALL_PORTCONF_ID $ALL_PORTCONF_ID --arg DISABLED_PORTCONF_ID $DISABLED_PORTCONF_ID --arg BLUE1_PORTCONF_ID $BLUE1_PORTCONF_ID --arg BLUE2_PORTCONF_ID $BLUE2_PORTCONF_ID --arg BLUE3_PORTCONF_ID $BLUE3_PORTCONF_ID "$DATA"`
    curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X PUT -k -s https://fms.nevermore:8443/api/s/default/rest/device/$1 > /dev/null
}

# $1: _id
configure_ap() {
    DATA='''
{
   "radio_table":[
      {
         "name":"ra0",
         "radio":"ng",
         "wlangroup_id":$EXTERNAL_WLAN_ID
      },
      {
         "name":"rai0",
         "radio":"na",
         "wlangroup_id":$FIELD_WLAN_ID
      }
   ]
}
'''
    DATA=`jq -n --arg EXTERNAL_WLAN_ID $EXTERNAL_WLAN_ID --arg FIELD_WLAN_ID $FIELD_WLAN_ID "$DATA"`
    curl -b "$COOKIEFILE" -d "$DATA" -H 'Content-Type: application/json' -X PUT -k -s https://fms.nevermore:8443/api/s/default/rest/device/$1 > /dev/null
}



entrypoint "$@"
exit $?
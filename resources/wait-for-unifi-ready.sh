#!/bin/sh

DELAY_INTERVAL=3
SECONDS_WAITED=0
MAX_SECONDS=180

while :
do
    SECONDS_WAITED=`expr $SECONDS_WAITED + $DELAY_INTERVAL`
    sleep $DELAY_INTERVAL
    
    ALL_CLEAR="true"
    DEVICEDATA=`curl -b "$COOKIEFILE" -k -s https://fms.nevermore:8443/api/s/default/stat/device-basic | jq '.data'`
    if [ $? != 0 ]; then
        continue
    fi
    NUM_OF_DEVICES=`echo $DEVICEDATA | jq '. | length'`
    if [ -z "$NUM_OF_DEVICES" ]; then
        echo Lost connection to controller \(${SECONDS_WAITED}s\)
        continue
    fi
    for i in `seq 0 $(expr $NUM_OF_DEVICES - 1)`; do #For each device
        DEVICE=`echo $DEVICEDATA | jq --argjson i $i '.[$i]'`
        STATE=`echo $DEVICE | jq '.state'`
        if [ $STATE != 1 ]; then 
            ALL_CLEAR="false"
            STATE_STRING="not ready"
            case $STATE in
                 0)
                    STATE_STRING="disconnected"
                    ;;
                2)
                    STATE_STRING="pending adoption"
                    ;;
                5)
                    STATE_STRING="provisioning"
                    ;;
                6)
                    STATE_STRING="not found"
                    ;;
                7)
                    STATE_STRING="adopting"
                    ;;
            esac
            echo `echo $DEVICE | jq -r '.type'`-`echo $DEVICE | jq -r '.model'` $STATE_STRING \(${SECONDS_WAITED}s\)
        fi
    done

    if [ $ALL_CLEAR = "true" ]; then
        return 0
    fi

    if [ $SECONDS_WAITED -gt $MAX_SECONDS ]; then
        echo "Reached maximum wait duration"
        return 1
    fi
done
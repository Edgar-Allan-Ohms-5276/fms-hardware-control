#!/bin/sh

# Tries to login to unifi controller and saves login cookies in returned tmpfile. It is the caller's responsibility to delete this file
# Exit code will be 0 if successful and 1 if not.

DATA=`jq -n --arg CONTROLLER_USERNAME $CONTROLLER_USERNAME --arg CONTROLLER_PASSWORD $CONTROLLER_PASSWORD '{"username": $CONTROLLER_USERNAME, "password": $CONTROLLER_PASSWORD}'`

tmpfile=$(mktemp)
echo $tmpfile

LOGIN_DATA=`curl -c $tmpfile -d "$DATA" -H 'Content-Type: application/json' -X POST -k -s https://fms.nevermore:8443/api/login`
SUCCESS=`echo $LOGIN_DATA | jq '.meta.rc == "ok"'`
if [ $SUCCESS = "true" ]; then
    return 0
else
    return 1
fi
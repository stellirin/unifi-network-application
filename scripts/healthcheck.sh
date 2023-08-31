#!/bin/bash

# Constants
APP_STATUS_UP="up"
APP_STATUS_DOWN="down"
APP_STATUS_MIGRATING="migrating"
STATUS_URL="http://localhost:8080/status"
STATUS_RESPONSE_FILE="/tmp/unifi-network-status-response"

function is_application_migrating() {
	[[ `cat "$STATUS_RESPONSE_FILE" | grep '"db_migrating":true'` != "" ]]
}

function is_application_up() {
	[[ `cat "$STATUS_RESPONSE_FILE" | grep '"server_running":true'` != "" ]]
}

function is_application_connected_to_mongo() {
	grep -q '"db_connected":true' "$STATUS_RESPONSE_FILE"
}

function get_application_status() {
    local status="$APP_STATUS_DOWN"
    local http_code=$(curl -s --connect-timeout 1 --max-time 5 -o "$STATUS_RESPONSE_FILE" -w "%{http_code}" "$STATUS_URL")
    if [ "${http_code}" == "200" ]
    then
        if is_application_migrating
        then
            status="$APP_STATUS_MIGRATING"
        elif is_application_up && is_application_connected_to_mongo
        then
            status="$APP_STATUS_UP"
        fi
    fi
    echo "$status"
}

application_status="$(get_application_status)"
if [[ $application_status == $APP_STATUS_UP ]]
then
    exit 0
fi

exit 1

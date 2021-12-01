#!/bin/bash
##FAILOVER PARAMETERS
##https://www.cloudns.net/wiki/article/274/

set -x
export $(xargs < .env)

# Create all wildcard records for each server
API_HOST=https://api.cloudns.net
API_PATH=/dns/failover-activate.json?
API_AUTH="auth-id=$CLOUDNS_AUTH_ID&auth-password=$CLOUDNS_AUTH_PASSWORD&"
echo "$API_AUTH"

# Get all dns records IDs and IPs
RECORD_ID_AND_IP=$(./dns/get-all-wildcards.sh | jq -r '. | {id,record} | join (",")') 

for RECORD_ID_AND_IP in $RECORD_ID_AND_IP
do
  echo "$RECORD_ID_AND_IP"
  RECORD_ID=$(echo $RECORD_ID_AND_IP | cut -d "," -f 1)
  RECORD_IP=$(echo $RECORD_ID_AND_IP | cut -d "," -f 2)

    echo "FAILOVER"
    echo $API_HOST$API_PATH$API_AUTH
    curl "$API_HOST$API_PATH$API_AUTH&domain-name=$DOMAIN&record-id=$RECORD_ID&check_type=8&host=*&record=$RECORD_IP&port=443&down_event_handler=1&up_event_handler=1&main_ip=$RECORD_IP&check_period=60&notification_mail=-1"
  done
 exit 0


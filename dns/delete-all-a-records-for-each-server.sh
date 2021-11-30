#!/bin/bash
set -x
export $(xargs < .env)

# WARNING DANGER: Will delete all DNS A records for given ip address

API_HOST=https://api.cloudns.net
API_PATH=/dns/delete-record.json?
API_AUTH=auth-id="$CLOUDNS_AUTH_ID&auth-password=$CLOUDNS_AUTH_PASSWORD&"

for SERVER_IP in $(cat ./servers.txt)
do
  A_RECORD_IDS=$(./dns/get-all-a-records.sh | jq -r --arg SERVER_IP "$SERVER_IP" 'select(.record | contains($SERVER_IP)) | {id} | join("")')

  for A_RECORD_ID in $A_RECORD_IDS
  do
    echo "About to delete A record for $SERVER_IP"
    curl "$API_HOST$API_PATH$API_AUTH&domain-name=$DOMAIN&record-id=$A_RECORD_ID"
  done
done

exit 0

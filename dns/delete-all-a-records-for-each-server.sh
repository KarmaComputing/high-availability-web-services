#!/bin/bash
set -x
export $(xargs < .env)

# WARNING DANGER: Will delete all DNS A records for given ip address

API_HOST=https://api.cloudns.net
API_PATH=/dns/delete-record.json?
API_AUTH=auth-id="$CLOUDNS_AUTH_ID&auth-password=$CLOUDNS_AUTH_PASSWORD&"

for SERVER_HOSTNAME in $(cat ./servers.txt)
do
  SERVER_IP=$(dig +short $SERVER_HOSTNAME)
  SERVER_IP=$(echo -n $SERVER_IP)
  A_RECORD_ID=$(./dns/get-all-a-records.sh | jq -r --arg SERVER_IP "$SERVER_IP" 'select(.record | contains($SERVER_IP)) | {id} | join("")')
  echo $A_RECORD_ID
  echo "About to delete A record for $SERVER_IP"
  curl "$API_HOST$API_PATH$API_AUTH&domain-name=$DOMAIN&record-id=$A_RECORD_ID"
done
exit 0

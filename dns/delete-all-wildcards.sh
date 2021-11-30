#!/bin/bash
set -x
export $(xargs < .env)

# WARNING DANGER: Will delete all wildcard DNS records for given domain.

API_HOST=https://api.cloudns.net
API_PATH=/dns/delete-record.json?
API_AUTH=auth-id="$CLOUDNS_AUTH_ID&auth-password=$CLOUDNS_AUTH_PASSWORD&"


./dns/get-all-wildcards.sh
echo "About to delete all above records"
sleep 10
WILDCARD_A_RECORD_IDS=$(./dns/get-all-wildcards.sh | jq -r '.id')

for WILDCARD_A_RECORD_ID in $WILDCARD_A_RECORD_IDS
do
  echo Deleting $WILDCARD_A_RECORD_ID
  curl "$API_HOST$API_PATH$API_AUTH&domain-name=$DOMAIN&record-id=$WILDCARD_A_RECORD_ID"
done


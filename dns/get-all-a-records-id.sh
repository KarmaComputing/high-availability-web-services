#!/bin/bash
set -x
export $(xargs < ../.env)

API_HOST=https://api.cloudns.net
API_PATH=/dns/records.json?
API_AUTH=auth-id="$CLOUDNS_AUTH_ID&auth-password=$CLOUDNS_AUTH_PASSWORD&"

curl "$API_HOST$API_PATH$API_AUTH&domain-name=$DOMAIN&type=a&rows-per-page=100&page=1" | jq '.[] | {id, host, record, type} | select(.type | contains("A"))' | grep "id" | cut -d '"' -f 4

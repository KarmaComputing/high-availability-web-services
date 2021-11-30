#!/bin/bash
set -x
export $(xargs < ../.env)

# Create all wildcard records for each server
API_HOST=https://api.cloudns.net
API_PATH=/dns/failover-activate.json?
API_AUTH="auth-id=$CLOUDNS_AUTH_ID&auth-password=$CLOUDNS_AUTH_PASSWORD&"
echo "$API_AUTH"
# Get all server IPs

SERVER_PUBLIC_IPS=$(../hetzner/hetzner-get-all-servers-ip-public-net.sh)
SERVER_RECORDS_ID=$(./get-all-a-records-id.sh)
for SERVER_PUBLIC_IP in $SERVER_PUBLIC_IPS 
  for SERVER_RECORDS_ID in $SERVER_RECORDS_ID
  do
  do
    echo "FAILOVER"
    echo $API_HOST$API_PATH$API_AUTH
    curl "$API_HOST$API_PATH$API_AUTH&domain-name=$DOMAIN&type=a&record-id=$MISSING&check_type=8&host=*&record=$SERVER_PUBLIC_IP&port=443&down_event_handler=1&up_event_handler=1&main_ip=$SERVER_PUBLIC_IP&check_period=60"

  done  
  done
  exit 0



#!/bin/bash
set -x
export $(xargs < .env)

# Create all wildcard records for each server
API_HOST=https://api.cloudns.net
API_PATH=/dns/add-record.json?
API_AUTH=auth-id="$CLOUDNS_AUTH_ID&auth-password=$CLOUDNS_AUTH_PASSWORD&"

# Get all server IPs

SERVER_PUBLIC_IPS=$(./hetzner/hetzner-get-all-servers-ip-public-net.sh)

for SERVER_PUBLIC_IP in $SERVER_PUBLIC_IPS
do
  echo "PKK"
  echo $API_HOST$API_PATH$API_AUTH
  curl "$API_HOST$API_PATH$API_AUTH&domain-name=$DOMAIN&type=a&record-type=A&host=*&record=$SERVER_PUBLIC_IP&ttl=60"
done

exit 0



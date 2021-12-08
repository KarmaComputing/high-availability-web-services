#!/bin/bash

set -x
export $(xargs <.env)

# Create n hetzner servers

NUMBER_OF_SERVERS=$1
DATACENTER=nbg1-dc3

CALLING_SCRIPT=$(ps --no-headers -o command $PPID)

if [[ $CALLING_SCRIPT =~ "hetzner-add-server.sh" ]]; then
  echo "Add single server"
  ADD_SINGLE_SERVER_REQUEST=true
fi


for INDEX in $(seq $NUMBER_OF_SERVERS)
do
  echo Creating server $n
  SERVER_NAME=$(cat /proc/sys/kernel/random/uuid)
  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"automount":false,"datacenter":"nbg1-dc3","firewalls":[],"image":"ubuntu-20.04","labels":{}, "name":"'$SERVER_NAME'","networks":[],"server_type":"cx11","ssh_keys":["chris@chris-ideapad","joel@ubuntu"],"start_after_create":true,"user_data":"","volumes":[]}' \
    'https://api.hetzner.cloud/v1/servers' > new-server.json
done

# If ADD_SINGLE_SERVER_REQUEST , then append new IP to servers.txt
if [ "$ADD_SINGLE_SERVER_REQUEST" = true ]; then
  NEW_SERVER_IP=$(cat new-server.json | jq -r .server.public_net.ipv4.ip)
  echo $NEW_SERVER_IP >> servers.txt
fi


echo $INDEX servers created





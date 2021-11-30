#!/bin/bash

set -x
export $(xargs <.env)

# Create n hetzner servers

NUMBER_OF_SERVERS=$1
DATACENTER=nbg1-dc3


for INDEX in $(seq $NUMBER_OF_SERVERS)
do
  echo Creating server $n
  SERVER_NAME=$(cat /proc/sys/kernel/random/uuid)
  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"automount":false,"datacenter":"nbg1-dc3","firewalls":[],"image":"ubuntu-20.04","labels":{}, "name":"'$SERVER_NAME'","networks":[],"server_type":"cx11","ssh_keys":["chris@chris-ideapad","joel@ubuntu"],"start_after_create":true,"user_data":"","volumes":[]}' \
    'https://api.hetzner.cloud/v1/servers'
done

echo $INDEX servers created





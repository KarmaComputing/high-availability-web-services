#!/bin/bash

set -x
export $(xargs <.env)

# Usage: ./hetzner/hetzner-create-n-servers.sh 3 cx11
# Note: Server type must be in lowercase

HETZNER_SSH_IDS=$(./hetzner/hetzner-get-all-ssh-keys.sh | jq -r '.ssh_keys[] | {id} | join("")')

# build array of ssh ids and remove the last ',' from the array TODO workout how to do this in jq
PREP_HETZNER_SSH_IDS_JSON_ARRAY=$(echo -n "[" && for ID in $HETZNER_SSH_IDS; do  echo -n $ID,; done; echo -n "]")
HETZNER_SSH_IDS_JSON_ARRAY=$(echo -n $PREP_HETZNER_SSH_IDS_JSON_ARRAY | sed 's/\(.*\),/\1/')

# Create n hetzner servers
NUMBER_OF_SERVERS=$1
SERVER_TYPE=$2

if [[ $# -ne 2 ]]
then
  echo WARNING: Using default server type cx11
  SERVER_TYPE=cx11
fi


DATACENTER=nbg1-dc3

CALLING_SCRIPT=$(ps --no-headers -o command $PPID)

if [[ $CALLING_SCRIPT =~ "hetzner-add-server.sh" ]]; then
  echo "Add single server"
  ADD_SINGLE_SERVER_REQUEST=true
fi

SERVERS_FILENAME=servers.txt
CALLING_SCRIPT=$(ps --no-headers -o command $PPID)

if [[ $CALLING_SCRIPT =~ "provision-database.sh" ]]; then
  SERVERS_FILENAME=db-servers.txt
fi

# Remove any blank lines from SERVERS_FILENAME
sed -i '/^$/d' $SERVERS_FILENAME


for INDEX in $(seq $NUMBER_OF_SERVERS)
do
  echo Creating server $n
  SERVER_NAME=$(cat /proc/sys/kernel/random/uuid)
  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"automount":false,"datacenter":"nbg1-dc3","firewalls":[],"image":"ubuntu-20.04","labels":{}, "name":"'$SERVER_NAME'","networks":[],"server_type":"'$SERVER_TYPE'","ssh_keys":'$HETZNER_SSH_IDS_JSON_ARRAY',"start_after_create":true,"user_data":"","volumes":[]}' \
    'https://api.hetzner.cloud/v1/servers' | tee new-server.json
    NEW_SERVER_IP=$(cat new-server.json | jq -r .server.public_net.ipv4.ip)
    echo $NEW_SERVER_IP >> $SERVERS_FILENAME
done

# If ADD_SINGLE_SERVER_REQUEST , then append new IP to servers.txt
if [ "$ADD_SINGLE_SERVER_REQUEST" = true ]; then
  echo $NEW_SERVER_IP >> $SERVERS_FILENAME
fi


echo $INDEX servers created





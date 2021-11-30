#!/bin/bash

set -x

# WARNING DANGER: Deletes all servers in given API_TOKEN project

export $(xargs <.env)

curl \
	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
	'https://api.hetzner.cloud/v1/servers' > hetzner-servers.json

SERVER_IDS=$(cat hetzner-servers.json | jq -r '.servers[]| {id} | join("")')

for SERVER_ID in $SERVER_IDS;
do
  echo "Deleting SERVER_ID: $SERVER_ID"
  curl \
  	-X DELETE \
  	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
  	-H "Content-Type: application/json" \
  	"https://api.hetzner.cloud/v1/servers/$SERVER_ID"
done


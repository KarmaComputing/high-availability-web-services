#!/bin/bash

set -x

# WARNING DANGER: Deletes all data on all servers and rebuild them.

export $(xargs <.env)

curl \
	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
	'https://api.hetzner.cloud/v1/images' > hetzner-images.json

curl \
	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
	'https://api.hetzner.cloud/v1/servers' > hetzner-servers.json

SERVER_IDS=$(cat hetzner-servers.json | jq -r '.servers[]| {id} | join("")')

for SERVER_ID in $SERVER_IDS;
do
  echo "Rebuilding SERVER_ID: $SERVER_ID"
  curl \
  	-X POST \
  	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
  	-H "Content-Type: application/json" \
  	-d '{"image":"ubuntu-20.04"}' \
  	"https://api.hetzner.cloud/v1/servers/$SERVER_ID/actions/rebuild"
done


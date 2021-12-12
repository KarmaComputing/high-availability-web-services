#!/bin/bash

set -x

# WARNING DANGER: Deletes all volumes in given API_TOKEN project

export $(xargs <.env)

curl \
	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
	'https://api.hetzner.cloud/v1/volumes' > hetzner-volumes.json

VOLUME_IDS=$(cat hetzner-volumes.json | jq -r '.volumes[]| {id} | join("")')

for VOLUME_ID in $VOLUME_IDS;
do
  echo "Detatching VOLUME_ID: $VOLUME_ID"
  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_API_TOKEN" \
    "https://api.hetzner.cloud/v1/volumes/$VOLUME_ID/actions/detach"
  sleep 2

  echo "Deleting VOLUME_ID: $VOLUME_ID"
  curl \
  	-X DELETE \
  	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
  	-H "Content-Type: application/json" \
  	"https://api.hetzner.cloud/v1/volumes/$VOLUME_ID"
done


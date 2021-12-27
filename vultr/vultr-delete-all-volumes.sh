#!/bin/bash

set -x

# WARNING DANGER: Deletes all volumes in vultr- ACCOUNT WIDE

export $(xargs <.env)

curl "https://api.vultr.com/v2/blocks" \
  -X GET \
  -H "Authorization: Bearer ${VULTR_API_KEY}" > vultr-volumes.json

VOLUME_IDS=$(cat vultr-volumes.json  | jq -r '.blocks[].id')

for VOLUME_ID in $VOLUME_IDS;
do
  echo "Detatching VOLUME_ID: $VOLUME_ID"

  curl "https://api.vultr.com/v2/blocks/$VOLUME_ID/detach" \
    -X POST \
    -H "Authorization: Bearer ${VULTR_API_KEY}" \
    -H "Content-Type: application/json" \
    --data '{
      "live" : true
    }'
  sleep 2

  echo "Deleting VOLUME_ID: $VOLUME_ID"

  curl "https://api.vultr.com/v2/blocks/$VOLUME_ID" \
    -X DELETE \
    -H "Authorization: Bearer ${VULTR_API_KEY}"
  sleep 2
done


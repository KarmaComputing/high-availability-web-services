#!/bin/sh

set -x
export $(xargs <.env)

curl "https://api.vultr.com/v2/instances?tag=$PAAS_NAME" \
  -X GET \
  -H "Authorization: Bearer ${VULTR_API_KEY}" > vultr-servers.json

VOLUME_IDS=$(./vultr/vultr-get-all-volume-ids.sh > vultr-volume-ids.txt)

NUM_LOOPS=$(wc -l < vultr-volume-ids.txt)

cat vultr-servers.json | jq -r '.instances[].id' > vultr-server-ids.txt
for i in $(seq 1 $NUM_LOOPS);
do
  # Get line n of the vultr-server-ids.txt
  SERVER_ID=$(sed -n "$i"p vultr-server-ids.txt)
  VOLUME_ID=$(sed -n "$i"p vultr-volume-ids.txt)
  echo "attaching VOLUME_ID $VOLUME_ID to SERVER_ID: $SERVER_ID"

  curl "https://api.vultr.com/v2/blocks/$VOLUME_ID/attach" \
    -X POST \
    -H "Authorization: Bearer ${VULTR_API_KEY}" \
    -H "Content-Type: application/json" \
    --data '{
      "instance_id" : "'$SERVER_ID'",
      "live" : true
    }'
done


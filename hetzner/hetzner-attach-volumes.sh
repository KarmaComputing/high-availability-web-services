#!/bin/sh

set -x
export $(xargs <.env)

curl \
  -v -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  'https://api.hetzner.cloud/v1/servers' > hetzner-servers.json

VOLUME_IDS=$(./hetzner/hetzner-get-all-volume-ids.sh > hetzner-volume-ids.txt)

NUM_LOOPS=$(wc -l < hetzner-volume-ids.txt)

cat hetzner-servers.json | jq -r '.servers[]| {id} | join("")' > hetzner-server-ids.txt
for i in $(seq 1 $NUM_LOOPS);
do
  # Get line n of the hetzner-server-ids.txt
  SERVER_ID=$(sed -n "$i"p hetzner-server-ids.txt)
  VOLUME_ID=$(sed -n "$i"p hetzner-volume-ids.txt)
  echo "attaching VOLUME_ID $VOLUME_ID to SERVER_ID: $SERVER_ID"

  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"automount":true,"server":"'$SERVER_ID'"}' \
    "https://api.hetzner.cloud/v1/volumes/$VOLUME_ID/actions/attach"
done


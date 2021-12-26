#!/bin/bash

set -x
export $(xargs <.env)

# Usage: ./vultr/vultr-create-n-volumes.sh 3 10
# Note: Server type must be in lowercase

# Create n vultr volumes
NUMBER_OF_VOLUMES=$1
VOLUME_SIZE=$2

if [[ $# -ne 2 ]]
then
  echo "Usage: vultr-create-n-volumes.sh <number of volumes> <size>"
  exit 255
fi

for INDEX in $(seq $NUMBER_OF_VOLUMES)
do
  echo Creating volume $n
  VOLUME_NAME=$(cat /proc/sys/kernel/random/uuid)

  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"automount":false,"format":"ext4","location":"nbg1","name":"'$VOLUME_NAME'","size":"'$VOLUME_SIZE'"}' \
    'https://api.vultr.cloud/v1/volumes'

  curl "https://api.vultr.com/v2/blocks" \
    -X POST \
    -H "Authorization: Bearer ${VULTR_API_KEY}" \
    -H "Content-Type: application/json" \
    --data '{
      "region" : "lax",
      "size_gb" : '"$VOLUME_SIZE"',
      "label" : "ceph"
    }'
done

echo $INDEX volumes created





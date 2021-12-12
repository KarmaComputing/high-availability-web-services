#!/bin/bash

set -x
export $(xargs <.env)

# Usage: ./hetzner/hetzner-create-n-volumes.sh 3 10
# Note: Server type must be in lowercase

# Create n hetzner volumes
NUMBER_OF_VOLUMES=$1
VOLUME_SIZE=$2

if [[ $# -ne 2 ]]
then
  echo "Usage: hetzner-create-n-volumes.sh <number of volumes> <size>"
  exit 255
fi


DATACENTER=nbg1-dc3

for INDEX in $(seq $NUMBER_OF_VOLUMES)
do
  echo Creating volume $n
  VOLUME_NAME=$(cat /proc/sys/kernel/random/uuid)

  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"automount":false,"format":"ext4","location":"nbg1","name":"'$VOLUME_NAME'","size":"'$VOLUME_SIZE'"}' \
    'https://api.hetzner.cloud/v1/volumes'
done

echo $INDEX volumes created





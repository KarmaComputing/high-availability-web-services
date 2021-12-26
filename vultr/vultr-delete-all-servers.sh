#!/bin/bash

set -x
export $(xargs <.env)
# DANGER, this will delete all servers in the Vultr account

if [ -z "$PAAS_NAME" ]
then
      echo "\$PAAS_NAME is empty, refusing to continue"
      echo "\$PAAS_NAME is used to filter instances on Vultr so"
      echo "that only project related instances are deleted"
      exit 255
fi


curl "https://api.vultr.com/v2/instances?tag=$PAAS_NAME" \
  -X GET \
  -H "Authorization: Bearer ${VULTR_API_KEY}" | jq -r '.instances[].id' > vultr-delete-instance-ids.txt

for INSTANCE_ID in $(cat vultr-delete-instance-ids.txt)
do
  # Delete instance
  curl "https://api.vultr.com/v2/instances/$INSTANCE_ID" \
    -X DELETE \
    -H "Authorization: Bearer ${VULTR_API_KEY}"
done

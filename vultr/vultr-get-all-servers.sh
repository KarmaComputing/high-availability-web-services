#!/bin/bash

set -x

# Get all vultr servers

export $(xargs <.env)

curl "https://api.vultr.com/v2/instances?tag=$PAAS_NAME" \
  -X GET \
  -H "Authorization: Bearer ${VULTR_API_KEY}"


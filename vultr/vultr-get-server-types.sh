#!/bin/bash

# Get instance types
set -x
export $(xargs <.env)

curl "https://api.vultr.com/v2/plans?type=all" \
  -X GET \
  -H "Authorization: Bearer ${VULTR_API_KEY}" > server-types.json


# Just show server types
cat server-types.json | jq '.plans[].id'

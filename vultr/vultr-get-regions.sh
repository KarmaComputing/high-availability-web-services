#!/bin/bash

# Get vultr regions
set -x
export $(xargs <.env)

curl "https://api.vultr.com/v2/regions" \
  -X GET \
  -H "Authorization: Bearer ${VULTR_API_KEY}" > regions.json

# Just show region ids
cat regions.json | jq -r '.regions[].id'

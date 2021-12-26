#!/bin/bash

set -x

export $(xargs <.env)

curl "https://api.vultr.com/v2/blocks" \
  -X GET \
  -H "Authorization: Bearer ${VULTR_API_KEY}" | jq -r '.blocks[].id'


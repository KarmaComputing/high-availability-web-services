#!/bin/bash

set -x

export $(xargs <.env)

curl "https://api.vultr.com/v2/ssh-keys" \
  -X GET \
  -H "Authorization: Bearer ${VULTR_API_KEY}"

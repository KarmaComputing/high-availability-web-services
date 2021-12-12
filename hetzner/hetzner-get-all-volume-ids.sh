#!/bin/bash

set -x

export $(xargs <.env)

curl \
    --silent \
      -H "Authorization: Bearer $HETZNER_API_TOKEN" \
        'https://api.hetzner.cloud/v1/volumes' | jq -r '.volumes[].id'


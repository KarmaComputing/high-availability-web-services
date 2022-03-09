#!/bin/bash

set -x
export $(xargs <.env)

# Usage: ./hetzner/hetzner-get-server-types.sh

  curl \
    -H "Authorization: Bearer $HETZNER_API_TOKEN" \
    'https://api.hetzner.cloud/v1/server_types'



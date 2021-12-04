#!/bin/bash

set -x

# WARNING DANGER: This will cause this server to self destruct

export $(xargs <.env)


INSTANCE_ID=$(curl http://169.254.169.254/hetzner/v1/metadata/instance-id)

echo "Self-descructing SERVER_ID: $INSTANCE_ID"
curl \
  -X DELETE \
  -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.hetzner.cloud/v1/servers/$INSTANCE_ID"

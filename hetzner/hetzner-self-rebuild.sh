#!/bin/bash

set -x

# WARNING DANGER: This will cause this server to remove all data and rebuild

export $(xargs <.env)


INSTANCE_ID=$(curl http://169.254.169.254/hetzner/v1/metadata/instance-id)

echo "Self-rebuilding INSTANCE_ID: $INSTANCE_ID"
curl \
  -X POST \
  -H "Authorization: Bearer $HETZNER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"image":"ubuntu-20.04"}' \
  "https://api.hetzner.cloud/v1/servers/$INSTANCE_ID/actions/rebuild"

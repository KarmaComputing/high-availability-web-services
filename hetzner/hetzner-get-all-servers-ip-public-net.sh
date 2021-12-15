#!/bin/bash

set -x

export $(xargs <.env)

curl \
  --silent \
	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
	'https://api.hetzner.cloud/v1/servers' | jq -r .servers[].public_net.ipv4.ip


#!/bin/bash

set -x

export $(xargs <.env)

curl \
	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
	'https://api.hetzner.cloud/v1/ssh_keys'


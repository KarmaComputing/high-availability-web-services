#!/bin/bash

set -x

# WARNING DANGER: Deletes all data on all servers and rebuild them.

export $(xargs <.env)

curl \
	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
	'https://api.hetzner.cloud/v1/servers'


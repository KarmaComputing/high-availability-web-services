#!/bin/bash

# DELETE all ssh public keys from Hetzner,

# Usage: ./hetzner/hetzner-delete-all-ssh-keys.sh

set -x
export $(xargs <.env)

for KEY_ID in $(./hetzner/hetzner-get-all-ssh-keys.sh | jq -r '.ssh_keys[] | {id} | join("")')
do
    curl \
        -X DELETE \
        -H "Authorization: Bearer $HETZNER_API_TOKEN" \
        "https://api.hetzner.cloud/v1/ssh_keys/$KEY_ID"
done





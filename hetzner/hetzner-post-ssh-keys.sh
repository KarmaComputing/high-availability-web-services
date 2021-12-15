#!/bin/bash

# POST all local ssh public keys in ~/.ssh to Hetzner,
# Name them based on filename + hostname seperated by a comman
# (e.g. id_rsa-alice-laptop)

# Usage: ./hetzner/hetzner-post-ssh-keys

set -x
export $(xargs <.env)

for KEY_PATH in $(ls ~/.ssh/*.pub)
do
    PUBLIC_KEY=$(cat $KEY_PATH)
    KEY_NAME=$(basename -z $KEY_PATH .pub; echo -n -$HOSTNAME)
    curl \
        -v \
        -X POST \
        -H "Authorization: Bearer $HETZNER_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"labels":{},"name":"'$KEY_NAME'","public_key":"'"$PUBLIC_KEY"'"}' \
        'https://api.hetzner.cloud/v1/ssh_keys'
done





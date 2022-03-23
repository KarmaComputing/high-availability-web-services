#!/bin/bash

# POST all local ssh public keys in ~/.ssh to Vultr,
# Name them based on filename + hostname seperated by a hyphen
# (e.g. id_rsa-alice-laptop)

# Usage: ./vultr/vultr-post-ssh-keys

set -x
export $(xargs <.env)

for KEY_PATH in $(ls ~/.ssh/*.pub)
do
    PUBLIC_KEY=$(cat $KEY_PATH)
    KEY_NAME=$(basename -z $KEY_PATH .pub; echo -n -$HOSTNAME)

    curl -v "https://api.vultr.com/v2/ssh-keys" \
      -X POST \
      -H "Authorization: Bearer ${VULTR_API_KEY}" \
      -H "Content-Type: application/json" \
      --data '{
        "name" : "'$KEY_NAME'",
        "ssh_key" : "'"$PUBLIC_KEY"'"
      }'
done





#!/bin/bash

set -x

export $(xargs <.env)

./vultr/vultr-get-all-servers.sh  | jq -r '.instances[].main_ip'

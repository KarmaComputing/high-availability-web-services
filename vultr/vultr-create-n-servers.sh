#!/bin/bash

# Create n vultr servers
set -x
export $(xargs <.env)


# Get instance types
#curl "https://api.vultr.com/v2/plans?type=vc2" \
#  -X GET \
#  -H "Authorization: Bearer ${VULTR_API_KEY}"

# Get os types
#curl "https://api.vultr.com/v2/os" \
#  -X GET \
#  -H "Authorization: Bearer ${VULTR_API_KEY}"
#

NUMBER_OF_SERVERS=$1
DATACENTER=sao
INSTANCE_TYPE=vc2-1c-1gb-sc1
OS_TPYE=445 # Ubuntu 21.04

# Note: Vultr does not allow creation of their smallest/cheapest
# instances via the api. Other providers do, like Hetzner and others.


for INDEX in $(seq $NUMBER_OF_SERVERS); do
   ( { echo "Creating server $INDEX" ;
      SERVER_NAME=$(cat /proc/sys/kernel/random/uuid)
      # Create the instance
      curl "https://api.vultr.com/v2/instances" \
        -X POST \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        -H "Content-Type: application/json" \
        --data '{
          "region" : "'$DATACENTER'",
          "plan" : "'$INSTANCE_TYPE'",
          "os_id" : '$OS_TPYE',
          "label" : "'$SERVER_NAME'",
          "hostname": "'$SERVER_NAME'"
        }' > ./vultr/instance.json

      # Get it's ip address (Vultr create api responds *before* an ip 
      # address gets assigned so we must poll.

      function getInstanceStatus()
      {
        INSTANCE_ID=$(cat ./vultr/instance.json | jq -r '.instance.id')

        curl "https://api.vultr.com/v2/instances/$INSTANCE_ID" \
          -X GET \
          -H "Authorization: Bearer ${VULTR_API_KEY}" | jq -r '.instance.status' > instance-status.txt
            if [ $(cat instance-status.txt) != 'active' ]
            then
              echo Vultr instance not active yet
              sleep 2
              getInstanceStatus
            fi
      }


      getInstanceStatus

      function getInstanceIP()
      {
        INSTANCE_ID=$(cat ./vultr/instance.json | jq -r '.instance.id')

        curl "https://api.vultr.com/v2/instances/$INSTANCE_ID" \
          -X GET \
          -H "Authorization: Bearer ${VULTR_API_KEY}" | jq -r '.instance.main_ip' > main_ip.txt
            if [ $(cat main_ip.txt) == '0.0.0.0' ]
            then
              echo Not got ip yet from vultr
              sleep 2
              getInstanceIP
            fi
      }

      getInstanceIP;} | \
    sed -e "s/^/Server $INDEX:/" ) &
done
wait

echo $INDEX servers created





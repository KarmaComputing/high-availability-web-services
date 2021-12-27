#!/bin/bash

# Create n vultr servers
set -x
export $(xargs <.env)

# Note: Vultr does not allow creation of their smallest/cheapest
# instances via the api. Other providers do, like Hetzner and others.


VULTR_SSH_IDS=$(./vultr/vultr-get-all-ssh-keys.sh | jq -r '.ssh_keys[].id')

# build array of ssh ids and remove the last ',' from the array TODO workout how to do this in jq
PREP_VULTR_SSH_IDS_JSON_ARRAY=$(echo -n "[" && for ID in $VULTR_SSH_IDS; do  echo -n \"$ID\",; done; echo -n "]")
VULTR_SSH_IDS_JSON_ARRAY=$(echo -n $PREP_VULTR_SSH_IDS_JSON_ARRAY | sed 's/\(.*\),/\1/')



# Get os types
#curl "https://api.vultr.com/v2/os" \
#  -X GET \
#  -H "Authorization: Bearer ${VULTR_API_KEY}"
#

NUMBER_OF_SERVERS=$1
SERVER_TYPE=$2
DATACENTER=$3

if [[ $# -eq 0 ]]
then
  echo Usage: ./vultr/vultr-create-n-servers.sh NUMBER_OF_SERVERS SERVER_TYPE REGION
  echo e.g ./vultr/vultr-create-n-servers.sh 3 vc2-1c-1gb lax
fi

if [[ $# -eq 1 ]]
then
  echo WARNING: Using default server type and default region
  SERVER_TYPE=vc2-1c-1gb
  DATACENTER=lax # lax = Los angeles
fi

if [[ $# -eq 2 ]]
then
  echo WARNING: Using default default region
  DATACENTER=lax # lax = Los angeles
fi

echo Using server type $SERVER_TYPE

SERVERS_FILENAME=servers.txt
CALLING_SCRIPT=$(ps --no-headers -o command $PPID)

if [[ $CALLING_SCRIPT =~ "provision-database.sh" ]]; then
  SERVERS_FILENAME=db-servers.txt
fi

if [[ $CALLING_SCRIPT =~ "provision-storage.sh" ]]; then
  SERVERS_FILENAME=storage-servers.txt
fi

# Remove any blank lines from SERVERS_FILENAME
sed -i '/^$/d' $SERVERS_FILENAME


OS_TPYE=387 # Ubuntu 20.04 x64


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
          "plan" : "'$SERVER_TYPE'",
          "os_id" : '$OS_TPYE',
          "label" : "'$SERVER_NAME'",
          "hostname": "'$SERVER_NAME'",
          "sshkey_id": '$VULTR_SSH_IDS_JSON_ARRAY',
          "tag": "'$PAAS_NAME'"
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

./vultr/vultr-get-all-servers-ip-public-net.sh > $SERVERS_FILENAME

echo $INDEX servers created





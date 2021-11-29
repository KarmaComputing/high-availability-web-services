#!/bin/bash
set -x

SERVERS="./servers.txt"

export $(xargs <.env)

for SERVER in $(cat $SERVERS); do
   ( { echo "output from $SERVER" ;
      ssh root@$SERVER /root/certs/renew-certs-web.sh $DOMAIN $CLOUDNS_AUTH_ID $CLOUDNS_AUTH_PASSWORD;} | \
    sed -e "s/^/$SERVER:/" ) &
done
wait

# Ref (looping ips)  https://unix.stackexchange.com/a/78594
# Ref (run in parallel against all servers) https://stackoverflow.com/a/26339345/885983

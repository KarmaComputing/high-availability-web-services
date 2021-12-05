#!/bin/bash
set -x

SERVERS="./servers.txt"

for SERVER in $(cat $SERVERS); do
   ( { echo "output from $SERVER" ;
      ssh root@$SERVER etcdctl endpoint status 2>/dev/null;} | \
    sed -e "s/^/$SERVER:/" ) &
done
wait

# Ref (looping ips)  https://unix.stackexchange.com/a/78594
# Ref (run in parallel against all servers) https://stackoverflow.com/a/26339345/885983

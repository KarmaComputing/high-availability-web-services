#!/bin/bash
set -x

SERVERS="./servers.txt"

for SERVER in $(cat $SERVERS); do
   ( { echo "output from $SERVER" ; 
      scp bootstrap.sh flake.sh httpsimpleserver stop.sh root@$SERVER:~;
      scp -v -r uwsgi root@$SERVER:~/;
      scp -v -r apache2 root@$SERVER:~/;
      scp -v -r dns root@$SERVER:~/;
      ssh root@$SERVER ./bootstrap.sh ; } | \
    sed -e "s/^/$SERVER:/" ) &
done
wait

# Ref (looping ips)  https://unix.stackexchange.com/a/78594
# Ref (run in parallel against all servers) https://stackoverflow.com/a/26339345/885983

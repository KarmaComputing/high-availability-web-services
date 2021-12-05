#!/bin/bash
set -x

# 1. Get leader
# 2. Fetch latest cert on etcd leader node, and store in etcd
# 3. On follower nodes, pull certs and restart apache

SERVERS="./servers.txt"
LEADER=""

export $(xargs <.env)

# Find out the current etcd leader node, and store in etcd
for SERVER in $(cat $SERVERS); do
    until ssh root@$SERVER date; do
    sleep 1
    done
    ssh root@$SERVER am-i-the-leader.sh
    returnValue=$?
    echo The returnValue is $returnValue
    if [ $returnValue -eq 0 ]
    then
      LEADER=$SERVER
      ssh root@$SERVER ./certs/renew-certs-web.sh $DOMAIN $CLOUDNS_AUTH_ID $CLOUDNS_AUTH_PASSWORD;
    fi
done


# On follower nodes, pull certs and restart apache
for SERVER in $(cat $SERVERS); do
   ( { echo "output from $SERVER" ;
      until ssh root@$SERVER date; do
      sleep 1
      done
      ssh root@$SERVER am-i-the-leader.sh
      returnValue=$?
      if [ $SERVER != $LEADER ]
      then
        ssh root@$SERVER ./certs/get-certs-from-etcd-reboot-apache.sh $DOMAIN;
      fi
      } | \
    sed -e "s/^/$SERVER:/" ) &
done
wait

# Ref (looping ips)  https://unix.stackexchange.com/a/78594
# Ref (run in parallel against all servers) https://stackoverflow.com/a/26339345/885983

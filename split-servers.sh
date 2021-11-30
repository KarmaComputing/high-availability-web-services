#!/bin/bash
set -x

SERVERS_LIST=servers.txt

PERCENT_TO_TAKE_OFFLINE=$1

if [ $1 -ge 1 ]
then
  echo 'PERCENT_TO_TAKE_OFFLINE cannot be 1 (100%). Example: 0.1 is 10% of servers'
  exit 255
fi

NUM_SERVERS=$(wc -l  < $SERVERS_LIST)

NUM_SERVER_PER_GROUP=$(printf %.$2f $(echo "$NUM_SERVERS * $PERCENT_TO_TAKE_OFFLINE" | bc))

echo $NUM_SERVER_PER_GROUP

rm -rf target_servers && mkdir target_servers
split -l $NUM_SERVER_PER_GROUP $SERVERS_LIST target_servers/targets-

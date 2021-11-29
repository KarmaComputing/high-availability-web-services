#!/bin/bash
set -x

SERVERS_LIST=servers.txt

PERCENT_TO_TAKE_OFFLINE=$1

NUM_SERVERS=$(wc -l  < $SERVERS_LIST)

NUM_SERVER_PER_GROUP=$(printf %.$2f $(echo "$NUM_SERVERS * $PERCENT_TO_TAKE_OFFLINE" | bc))

echo $NUM_SERVER_PER_GROUP

rm -rf target_servers && mkdir target_servers
split -l $NUM_SERVER_PER_GROUP $SERVERS_LIST target_servers/targets-

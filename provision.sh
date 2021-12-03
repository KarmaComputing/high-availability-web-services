#!/bin/bash
set -x
# Rules:
# - There is no single node which must be online
# - Don't take all servers offline at once
# - Always have a % online *and* able to serve requests
# - Continually destory & re-create a % of the servers
# - Serve all requests over tls / https
#

export $(xargs <.env)

PERCENT_AT_ONCE=$1


NUM_SERVERS=$(cat servers.txt | wc -l)
echo "There are $NUM_SERVERS in total"

ETCD_DISCOVERY=$(curl https://discovery.etcd.io/new?size=$NUM_SERVERS)

if [ -z "$PERCENT_AT_ONCE" ]
then
      echo "\$PERCENT_AT_ONCE is empty, defaulting to 0.5"
      PERCENT_AT_ONCE=0.5
else
      echo "\$PERCENT_AT_ONCE is set to $PERCENT_AT_ONCE"
fi

./split-servers.sh $PERCENT_AT_ONCE
TARGET_SERVERS="target_servers/*"


echo "Starting rollout"
echo -n .
sleep 1
echo -n .
sleep 1
echo -n .
sleep 3

for SERVER_GROUP in $TARGET_SERVERS
do 
  echo "Provisoning group $SERVER_GROUP"
  NUM_SERVERS_IN_GROUP=$(cat $SERVER_GROUP | wc -l)
  echo "There are $NUM_SERVERS_IN_GROUP in this group"

  for SERVER in $(cat $SERVER_GROUP); do
     ( { echo "output from $SERVER" ;
        scp whats-my-ip.sh root@$SERVER:~;
        scp servers.txt root@$SERVER:~;
        scp bootstrap.sh stop.sh root@$SERVER:~;
        scp -v -r uwsgi root@$SERVER:~/;
        scp -v -r apache2 root@$SERVER:~/;
        scp -v -r dns root@$SERVER:~/;
        scp -v -r etcd root@$SERVER:~/;
        scp -v -r certbot root@$SERVER:~/;
        scp -v -r certs root@$SERVER:~/;
        ssh root@$SERVER ./bootstrap.sh $ETCD_DISCOVERY $DOMAIN $CLOUDNS_AUTH_ID $CLOUDNS_AUTH_PASSWORD;
        ssh root@$SERVER reboot;
        sleep 120;
        ssh root@$SERVER /root/certs/renew-certs-web.sh $DOMAIN $CLOUDNS_AUTH_ID $CLOUDNS_AUTH_PASSWORD;} | \
      sed -e "s/^/$SERVER:/" ) &
  done
  wait

done


# Ref (looping ips)  https://unix.stackexchange.com/a/78594
# Ref (run in parallel against all servers) https://stackoverflow.com/a/26339345/885983

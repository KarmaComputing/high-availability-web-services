#!/bin/bash
set -x
CALLING_SCRIPT=$(ps --no-headers -o command $PPID)

if [[ $CALLING_SCRIPT =~ "day2.sh" ]]; then
  echo "This is day2"
  THIS_IS_DAY_2=true
fi

# Rules:
# - There is no single node which must be online
# - Don't take all servers offline at once
# - Always have a % online *and* able to serve requests
# - Continually destory & re-create a % of the servers
# - Serve all requests over tls / https
#

#set -a; . .env; set +a

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

for SERVER_GROUP in $TARGET_SERVERS
do 
  echo "Provisoning group $SERVER_GROUP"
  NUM_SERVERS_IN_GROUP=$(cat $SERVER_GROUP | wc -l)
  echo "There are $NUM_SERVERS_IN_GROUP in this group"

  for SERVER in $(cat $SERVER_GROUP); do
     ( { echo "output from $SERVER" ;
        if [ "$THIS_IS_DAY_2" = true ]; then
          #echo "This is day two, rebuilding server"
          #(
          #  ssh root@$SERVER /root/hetzner/hetzner-self-rebuild.sh;
          #) &
          #disown %1

          until ssh root@$SERVER date; do
          sleep 5
          done
        fi
        scp bootstrap.tar.gz root@$SERVER:~;
        ssh root@$SERVER mkdir -p /root/bootstrap;
        ssh root@$SERVER tar xvf bootstrap.tar.gz -C /root/bootstrap;
        ssh root@$SERVER mv /root/bootstrap/* /root;
        ssh root@$SERVER mv /root/bootstrap/.* /root;
        ssh root@$SERVER rm -f /root/bootstrap;
        ssh root@$SERVER ./bootstrap.sh $ETCD_DISCOVERY $DOMAIN $CLOUDNS_AUTH_ID $CLOUDNS_AUTH_PASSWORD;
        ssh root@$SERVER reboot;
        echo Finished $SERVER;} | \
      sed -e "s/^/$SERVER:/" ) &
  done
  wait

done


# Ref (looping ips)  https://unix.stackexchange.com/a/78594
# Ref (run in parallel against all servers) https://stackoverflow.com/a/26339345/885983

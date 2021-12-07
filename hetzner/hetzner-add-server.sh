#!/bin/bash

set -x
export $(xargs <.env)

tar -cvzf /tmp/bootstrap.tar.gz .
mv /tmp/bootstrap.tar.gz ./

# Add 1 hetzner server
./hetzner/hetzner-create-n-servers.sh 1
SERVER=$(cat servers.txt | tail -n 1)

./dns/create-all-wildcards.sh
./dns/create-health-check.sh

until ssh root@$SERVER date; do
sleep 5
done

scp bootstrap.tar.gz root@$SERVER:~;
ssh root@$SERVER mkdir -p /root/bootstrap;
ssh root@$SERVER tar xvf bootstrap.tar.gz -C /root/bootstrap;
ssh root@$SERVER mv /root/bootstrap/* /root;
ssh root@$SERVER mv /root/bootstrap/.* /root;
ssh root@$SERVER rm -f /root/bootstrap;
ssh root@$SERVER ./bootstrap.sh $ETCD_DISCOVERY $DOMAIN $CLOUDNS_AUTH_ID $CLOUDNS_AUTH_PASSWORD;
ssh root@$SERVER reboot;




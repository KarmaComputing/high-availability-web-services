#!/bin/bash
set -x

etcdctl endpoint status --cluster -w table

DOMAIN=$1
CLOUDNS_AUTH_ID=$2
CLOUDNS_AUTH_PASSWORD=$3

sleep 60

if [ am-i-the-leader.sh ]
then
    echo $HOSTNAME is the leader
    echo "Getting certificate using acme"
    export CLOUDNS_AUTH_ID=$CLOUDNS_AUTH_ID
    export CLOUDNS_AUTH_PASSWORD=$CLOUDNS_AUTH_PASSWORD
    /root/.acme.sh/acme.sh --test --force --issue -d $DOMAIN  -d "*.$DOMAIN" --dns dns_cloudns
    # Store in etcd
    cat /root/.acme.sh/$DOMAIN/fullchain.cer | etcdctl put fullchain.cer
    cat /root/.acme.sh/$DOMAIN/$DOMAIN.key | etcdctl put $DOMAIN.key

    a2ensite uwsgi-ssl
    systemctl stop apache2
    systemctl start apache2
    systemctl reload apache2
fi

sleep 120 # Wait for leader to get certificate

mkdir -p /root/.acme.sh/$DOMAIN/

# Install certificate (this happens on all nodes)
etcdctl get --print-value-only fullchain.cer > /root/.acme.sh/$DOMAIN/fullchain.cer
etcdctl get --print-value-only $DOMAIN.key > /root/.acme.sh/$DOMAIN/$DOMAIN.key

systemctl stop apache2.service
systemctl restart apache2.service

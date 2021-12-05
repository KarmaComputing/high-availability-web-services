#!/bin/bash
set -x

DOMAIN=$1

# If I'm not the leader, get the certs out of etcd
etcdctl endpoint status --cluster -w table

am-i-the-leader.sh
retVal=$?
if [ $retVal -ne 0 ]
then
  mkdir -p /root/.acme.sh/$DOMAIN/

  # Install certificate (this happens on all nodes)
  etcdctl get --print-value-only fullchain.cer > /root/.acme.sh/$DOMAIN/fullchain.cer
  etcdctl get --print-value-only $DOMAIN.key > /root/.acme.sh/$DOMAIN/$DOMAIN.key
  a2ensite uwsgi-ssl
  systemctl stop apache2.service
  systemctl start apache2.service
fi


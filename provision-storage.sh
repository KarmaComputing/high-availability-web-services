#!/bin/bash

if [ -z $DEBUG_MODE ]
then
  set +x
else
  echo Turning on debug mode
  set -x
fi

rm -f storage-servers.txt
touch storage-servers.txt

./vultr/vultr-create-n-servers.sh 3 vc2-1c-2gb
./vultr/vultr-create-n-volumes.sh 3 10
sleep 35
./vultr/vultr-attach-volumes.sh
sleep 120
./storage/install-ceph.sh


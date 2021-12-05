#!/bin/bash
set -x

echo $#

if [ $# -ne 3 ]
then
  echo 'Usage ./day0.sh <domain> <number-of-servers> <percent-at-once>'
  echo 'e.g. ./day0.sh example.com 5 1 # means deploy 5 servers, all at once (100% in parallel)'
  exit 1
fi

DOMAIN=$1
NUMBER_OF_SERVERS=$2
PERCENT_AT_ONCE=$3

if [ -z "$PERCENT_AT_ONCE" ]
then
      echo "\$PERCENT_AT_ONCE is empty, defaulting to 1 (100%)"
      PERCENT_AT_ONCE=1
else
      echo "\$PERCENT_AT_ONCE is set to $PERCENT_AT_ONCE"
fi


rm -rf ./run
# Copy over/create dirs
find . -type d -not -path './*git*' -not -path './*run*' -print -exec mkdir -p './run/{}' \;
# Copy over/create files into dirs
find . -type f -not -path './*git*' -not -path './*run*' -print -exec cp -a '{}' 'run/{}' \;

# Change to run directory
cd run
./rename-domain.sh example.co.uk $DOMAIN
./hetzner/hetzner-create-n-servers.sh $NUMBER_OF_SERVERS
sleep 30 #wait for servers to boot
./hetzner/hetzner-get-all-servers-ip-public-net.sh > servers.txt

tar -cvzf /tmp/bootstrap.tar.gz .
mv /tmp/bootstrap.tar.gz ./
./dns/create-all-wildcards.sh
./dns/create-health-check.sh
./provision.sh $PERCENT_AT_ONCE
sleep 60 # wait for quorum
./refresh-certs.sh

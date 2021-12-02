#!/bin/bash
set -x

echo $#

if [ $# -ne 1 ]
then
  echo 'Usage ./day0.sh <domain>'
  echo 'e.g. ./day0.sh example.com'
  exit 1
fi

rm -rf ./run
# Copy over/create dirs
find . -type d -not -path './*git*' -not -path './*run*' -print -exec mkdir -p './run/{}' \;
# Copy over/create files into dirs
find . -type f -not -path './*git*' -not -path './*run*' -print -exec cp -a '{}' 'run/{}' \;

# Change to run directory
cd run
pwd

./rename-domain.sh example.co.uk $1

./hetzner/hetzner-create-n-servers.sh 3
cp servers.txt servers.bk
./hetzner/hetzner-get-all-servers-ip-public-net.sh > servers.txt
./dns/create-all-wildcards.sh
./dns/create-health-check.sh
sleep 60 # wait for servers to boot
./provision.sh

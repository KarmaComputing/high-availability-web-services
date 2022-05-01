#!/bin/bash
set -x

echo $#

if [ $# -eq 3 ] || [ $# -eq 5 ];
then
  echo Permiting basic usage or advanced usage
else
  echo 'Usage ./day0.sh <domain> <number-of-servers> <percent-at-once>'
  echo 'Advanced Usage ./day0.sh <domain> <number-of-servers> <percent-at-once> <server-type> <image-name>'
  echo 'e.g. ./day0.sh example.com 5 1 # means deploy 5 servers, all at once (100% in parallel)'
  echo 'e.g. ./day0.sh example.com 5 1 cx11 ubuntu-20.04  # means deploy 5 servers, all at once (100% in parallel),'
  echo ' with server type cx11, using image ubuntu-20.04.'
  exit 1
fi

# Start local ssh-agent if ssh-agent is not running, and add ssh key to agent
if [ -z "$SSH_AUTH_SOCK" ]
then
    echo Starting ssh agent and restarting script because ssh agent was not loaded
    # See https://serverfault.com/a/547929/125827 and https://unix.stackexchange.com/a/405166
    exec ssh-agent bash -c "ssh-add ; $0 $@"
fi

echo The following ssh keys are loaded:
ssh-add -l

DOMAIN=$1
NUMBER_OF_SERVERS=$2
PERCENT_AT_ONCE=$3

if [[ $# -eq 5 ]]
then
  SERVER_TYPE=$4
  IMAGE_NAME=$5
else
  IMAGE_NAME=ubuntu-20.04
  SERVER_TYPE=cx11
fi

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
# Clear servers.txt
echo "" > servers.txt
./rename-domain.sh example.co.uk $DOMAIN
# Place public ssh keys in account so future servers are populated with keys
./hetzner/hetzner-post-ssh-keys.sh # Place public ssh keys in account so future servers are populated with keys
./hetzner/hetzner-create-n-servers.sh $NUMBER_OF_SERVERS $SERVER_TYPE $IMAGE_NAME
sleep 30 #wait for servers to boot

# Remove previous known_hosts entry (needed if re-running day0)
for IP in $(cat servers.txt)
do
    ssh-keygen -f ~/.ssh/known_hosts -R "$IP"
done
# Update ~/.ss/known_hosts for ssh
ssh-keyscan -t ssh-rsa -f servers.txt >> ~/.ssh/known_hosts


tar -cvzf /tmp/bootstrap.tar.gz .
mv /tmp/bootstrap.tar.gz ./
./dns/create-all-wildcards.sh
./dns/create-health-check.sh
./provision.sh $PERCENT_AT_ONCE
sleep 60 # wait for quorum
./refresh-certs.sh

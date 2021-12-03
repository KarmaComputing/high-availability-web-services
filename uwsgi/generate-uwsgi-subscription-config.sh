#!/bin/bash

echo '[uwsgi]'
echo '# This config is injected into all vassals'
echo '# Use random port'
echo '# See: https://uwsgi-docs.readthedocs.io/en/latest/Fastrouter.html#way-4-fastrouter-subscription-server'
echo 'socket = @(exec:///usr/local/bin/whats-my-ip.sh):0'

# See https://uwsgi-docs.readthedocs.io/en/latest/Configuration.html#magic-variables
echo 'address= @(%Daddress.txt)'


# Announce this app to every subscription server (so that
# uwsgi fastrouter can route each app)
# Note: you can/must? use the subcription server ip address here
# not the hostname.
for SERVER_IP in $(cat /root/servers.txt)
do
        echo "subscribe-to = $SERVER_IP:7000:%(address)"
done

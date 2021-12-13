#!/bin/bash
./dns/delete-all-wildcards.sh
./dns/delete-all-a-records-for-each-server.sh
./hetzner/hetzner-delete-all-volumes.sh
./hetzner/hetzner-delete-all-servers.sh

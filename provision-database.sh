#!/bin/bash
set -x

./hetzner/hetzner-create-n-servers.sh 3
./hetzner/hetzner-get-all-servers-ip-public-net.sh > servers.txt

sleep 5

# Create 3 volumes each with 10gb each
./hetzner/hetzner-create-n-volumes.sh 3 10
sleep 15

echo Attach one of each volume to each of the servers
./hetzner/hetzner-attach-volumes.sh

for SERVER in $(cat servers.txt)
do
  # configure fstab mount options
  ssh root@$SERVER "bash -s" -- < ./hetzner/hetzner-set-volume-mount-options.sh
  ssh root@$SERVER 'echo "vm.swappiness = 0">> /etc/sysctl.conf && swapoff -a && swapon -a && sysctl -p'

  scp systemd/system/disable-transparent-huge-pages.service root@$SERVER:/etc/systemd/system/disable-transparent-huge-pages.service
  ssh root@$SERVER systemctl daemon-reload
  ssh root@$SERVER systemctl start disable-transparent-huge-pages
  ssh root@$SERVER systemctl enable disable-transparent-huge-pages
  # Verify huge pages off
  ssh root@$SERVER cat /sys/kernel/mm/transparent_hugepage/enabled
done


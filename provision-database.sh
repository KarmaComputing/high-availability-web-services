#!/bin/bash

if [ -z $DEBUG_MODE ]
then
  set +x
else
  echo Turning on debug mode
  set -x
fi

./hetzner/hetzner-create-n-servers.sh 3 cpx11
./hetzner/hetzner-get-all-servers-ip-public-net.sh > db-servers.txt

sleep 5

# Create 3 volumes each with 10gb each
./hetzner/hetzner-create-n-volumes.sh 3 10
sleep 15

echo Attach one of each volume to each of the servers
./hetzner/hetzner-attach-volumes.sh

# Generate keys to bootstrap Tidb cluster
ssh-keygen -f id_rsa -N "" <<< y

for SERVER in $(cat db-servers.txt)
do
  ssh root@$SERVER apt update
  echo Copy key for bootstraping Tidb cluster
  scp id_rsa* root@$SERVER:/root/.ssh
  ssh root@$SERVER tee -a .ssh/authorized_keys < id_rsa.pub
  for TARGET in $(cat db-servers.txt)
  do
    ssh root@$TARGET -C "ssh-keyscan -H $TARGET >> ~/.ssh/known_hosts"
  done
  
  # configure fstab mount options
  ssh root@$SERVER "bash -s" -- < ./hetzner/hetzner-set-volume-mount-options.sh
  # Configure sysctl
  ssh root@$SERVER "bash -s" -- < ./sysctl/set-sysctl.sh
  # Configure /etc/security/limits.conf
  ssh root@$SERVER "bash -s" -- < ./limits/set-limits.sh
  ssh root@$SERVER 'echo "vm.swappiness = 0">> /etc/sysctl.conf && swapoff -a && swapon -a && sysctl -p'

  scp systemd/system/disable-transparent-huge-pages.service root@$SERVER:/etc/systemd/system/disable-transparent-huge-pages.service
  ssh root@$SERVER systemctl daemon-reload
  ssh root@$SERVER systemctl start disable-transparent-huge-pages
  ssh root@$SERVER systemctl enable disable-transparent-huge-pages
  # Verify huge pages off
  ssh root@$SERVER cat /sys/kernel/mm/transparent_hugepage/enabled
  # Enable & start irqbalance
  ssh root@$SERVER systemctl start irqbalance
  ssh root@$SERVER systemctl enable irqbalance
  # Install numactl
  ssh root@$SERVER apt install numactl
  ssh root@$SERVER reboot
done
sleep 35
# Install TiUP on first node
./tidb/generate-tidb-topology.sh > ./topology.yaml
scp topology.yaml root@$(sed -n 1p db-servers.txt):~
ssh root@$(sed -n 1p db-servers.txt) -C "curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh"
ssh root@$(sed -n 1p db-servers.txt) -C "export PATH=/root/.tiup/bin:$PATH && tiup cluster"
ssh root@$(sed -n 1p db-servers.txt) -C "export PATH=/root/.tiup/bin:$PATH && tiup update --self && tiup update cluster"
ssh root@$(sed -n 1p db-servers.txt) -C "export PATH=/root/.tiup/bin:$PATH && tiup --binary cluster"
ssh root@$(sed -n 1p db-servers.txt) -C "export PATH=/root/.tiup/bin:$PATH && tiup cluster check ./topology.yaml"
RETURN_CODE=$?
if [ $RETURN_CODE -ne 0 ]
then
  echo Did not pass tiup cluster check, refusing to install
  exit 255
fi
# Deploy TiDB cluster
ssh root@$(sed -n 1p db-servers.txt) -C "export PATH=/root/.tiup/bin:$PATH && tiup cluster deploy tidb-database v5.3.0 ./topology.yaml <<< y" #auto confirm yes
# Start the TiDB cluster
ssh root@$(sed -n 1p db-servers.txt) -C "export PATH=/root/.tiup/bin:$PATH && tiup cluster start tidb-database"
# List the clusters (we only created one)
ssh root@$(sed -n 1p db-servers.txt) -C "export PATH=/root/.tiup/bin:$PATH && tiup cluster list"
# Show status of cluster
ssh root@$(sed -n 1p db-servers.txt) -C "export PATH=/root/.tiup/bin:$PATH && tiup cluster display tidb-database"
# Install mysql-client (for testing only)
ssh root@$(sed -n 1p db-servers.txt) -C "apt-get install -y mysql-client"
# Verify mysql protocol and Tidb
ssh root@$(sed -n 1p db-servers.txt) -C "mysql -h 127.0.0.1 -P 4000 -e 'SELECT NOW()'"
# Set password: 
echo Important: Set password now. Connect to cluster and issue e.g. SET PASSWORD='secret'

echo Setting randomly generated password for database cluster
DB_PASSWORD_LENGTH=$(shuf -i 25-65 -n 1)
DB_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c $DB_PASSWORD_LENGTH; echo '')

mysql -u root -P 4000 -h $(sed -n 1p db-servers.txt) -e "SET PASSWORD='$DB_PASSWORD')'"
echo "Connect to the database cluster:"
echo "mysql -u root -P 4000 -h $(sed -n 1p db-servers.txt)" -p
echo The DB_PASSWORD is: $DB_PASSWORD

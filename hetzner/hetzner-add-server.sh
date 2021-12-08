#!/bin/bash

set -x

# Create a new server
# Push the new servers.txt to all nodes? eh?
#   - Maybe store all nodes in etcd? Chicken and egg much
#   - Perform an intersection / merge- does not matter
#     if we insert duplicate hosts by mistake,
#     what *does* hurt is if we miss hosts which are
#     up- does it really matter though? They'll auto
#     self-destruct anyway if they fail to get added
#     (but what a waste..)
#   - Potential backup etcd/restore then completely
#     destroy it/recreate it with new number of noes?
#     Wasteful/bruteforce, but at least it's simpler than
#     adding new members: (https://etcd.io/docs/v3.5/tutorials/how-to-deal-with-membership/)
#     seems less hasstle just to totaly destroy etcd and
#     restore it from backup? MUST therefore allow nodes
#     to function without a connection to etcd (this is
#     already the case, but needs to be remebered), don't
#     reply on etcd- this is also not true, the tls
#     letsencrypt process relies on etcd being up (at least
#     *only* for creating / renewing certificates) etcd does
#     *not* need to be up all the time.
#     If the backup restore approach is to be taken, then
#     if might be good to think of even the initial bootstrap#     to be a restore of the etcd cluster (there's no such
#     thing as day0 in these sorts of systems).
#     https://etcd.io/docs/v3.5/op-guide/recovery/#restoring-a-cluster

set -x
export $(xargs <.env)

# Add 1 hetzner server
./hetzner/hetzner-create-n-servers.sh 1
NEW_SERVER=$(cat servers.txt | tail -n 1)

./dns/create-all-wildcards.sh
./dns/create-health-check.sh

until ssh root@$NEW_SERVER date; do
sleep 5
done

tar -cvzf /tmp/bootstrap.tar.gz .
mv /tmp/bootstrap.tar.gz ./

scp bootstrap.tar.gz root@$NEW_SERVER:~;
ssh root@$NEW_SERVER mkdir -p /root/bootstrap;
ssh root@$NEW_SERVER tar xvf bootstrap.tar.gz -C /root/bootstrap;
ssh root@$NEW_SERVER mv /root/bootstrap/* /root;
ssh root@$NEW_SERVER mv /root/bootstrap/.* /root;
ssh root@$NEW_SERVER rm -f /root/bootstrap;

# Get latest list of server ips from Hetzner
# To verify servers.txt has no old IPs by asking Hetzner to list all server ips in the account
HETZNER_SERVER_IPS=$(./hetzner/hetzner-get-all-servers-ip-public-net.sh)
rm servers.txt
for IP in $HETZNER_SERVER_IPS
do
 echo $IP >> servers.txt
done

# Copy updated servers.txt to every node
for SERVER in $(cat servers.txt)
do
   scp -o ConnectTimeout=5 servers.txt root@$SERVER:~/servers.txt
done

exit 255

NUM_SERVERS=$(cat servers.txt | wc -l)
echo "There are $NUM_SERVERS in total"
ETCD_DISCOVERY=$(curl https://discovery.etcd.io/new?size=$NUM_SERVERS)

ssh root@$NEW_SERVER ./bootstrap.sh $ETCD_DISCOVERY $DOMAIN $CLOUDNS_AUTH_ID $CLOUDNS_AUTH_PASSWORD;
ssh root@$NEW_SERVER reboot;
sleep 30

# Reset etcd
# 1. Backup tls certificates
# 2. Re-install/start etcd cluster with new number of nodes
# 3. Check if certificates can be restored on nodes which already have them
#   - If any node can locate a certificate from its backup, and
#     its not expired, then etcdctl put the certificate and key to etcd
#     if it cannot, then ?wait? x period because other nodes may still be
#     able to restore their certificate from backup.
#     after x timeout, refresh certificates, but only if the node is
#     an elected leader of the etcd cluster

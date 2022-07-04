#!/bin/bash

# Ref https://docs.ceph.com/en/pacific/cephadm/install/

set -x


# Install ceph and required tools (podman) on every ceph node
for SERVER in $(cat ./storage-servers.txt) ; do
   ( { echo "output from $SERVER" ;
      scp ./storage/bootstrap-ceph.sh root@$SERVER:~;
      ssh -t root@$SERVER 'sudo mv bootstrap-ceph.sh /root/bootstrap-ceph.sh'
      ssh -t root@$SERVER "sudo bash /root/bootstrap-ceph.sh $SERVER";
 } | \
    sed -e "s/^/$SERVER:/" ) &
done
wait


# Bootstrap ceph first node
IP_FIRST_CEPH_NODE=$(sed -n 1p storage-servers.txt)
scp ./storage/bootstrap-ceph-first-node.sh root@$IP_FIRST_CEPH_NODE:~
ssh root@$IP_FIRST_CEPH_NODE bash bootstrap-ceph-first-node.sh $IP_FIRST_CEPH_NODE

echo The ip address of the first ceph node is `$(echo sed -n 1p storage-servers.txt)`

## TODO join all nodes to cluster

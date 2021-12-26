#!/bin/bash

# Ref https://docs.ceph.com/en/pacific/cephadm/install/

set -x


IP_FIRST_CEPH_NODE=$(sed -n 1p storage-servers.txt)

# Install ceph and required tools (podman) on every ceph node
for IP in $(cat storage-servers.txt | grep -v $IP_FIRST_CEPH_NODE)
do
  scp ./storage/bootstrap-ceph.sh root@$IP:~
  ssh root@$IP bash bootstrap-ceph.sh $IP
done

# Bootstrap ceph first node
scp ./storage/bootstrap-ceph-first-node.sh root@$IP_FIRST_CEPH_NODE:~
ssh root@$IP_FIRST_CEPH_NODE bash bootstrap-ceph-first-node.sh $IP_FIRST_CEPH_NODE

# TODO join all nodes to cluster


#!/bin/bash

# See https://docs.ceph.com/en/pacific/cephadm/install/#running-the-bootstrap-command
#
#This command will:
#
#    Create a monitor and manager daemon for the new cluster on the local host.
#
#    Generate a new SSH key for the Ceph cluster and add it to the root user’s /root/.ssh/authorized_keys file.
#
#    Write a copy of the public key to /etc/ceph/ceph.pub.
#
#    Write a minimal configuration file to /etc/ceph/ceph.conf. This file is needed to communicate with the new cluster.
#
#    Write a copy of the client.admin administrative (privileged!) secret key to /etc/ceph/ceph.client.admin.keyring.
#
#    Add the _admin label to the bootstrap host. By default, any host with this label will (also) get a copy of /etc/ceph/ceph.conf and /etc/ceph/ceph.client.admin.keyring.

IP=$1
./cephadm bootstrap --mon-ip $IP # Only ran on first ceph node initial bootstrap

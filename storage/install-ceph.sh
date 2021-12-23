#!/bin/bash

# Ref https://docs.ceph.com/en/pacific/cephadm/install/
# First install podman, needed by cephadm

# TODO create and mount n volumes

. /etc/os-release

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -

apt-get update
apt-get -y upgrade
apt-get -y install podman

# Now bootstrap ceph

curl --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm

chmod +x cephadm

./cephadm add-repo --release octopus

./cephadm install

which cephadm

cephadm bootstrap --mon-ip $IP # first server ip

# Add ceph utils
cephadm add-repo --release octopus
cephadm install ceph-common

ceph status

# Add storage
ceph orch apply osd --all-available-devices

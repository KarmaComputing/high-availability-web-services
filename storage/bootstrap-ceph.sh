#!/bin/bash

IP_FIRST_CEPH_NODE=$1

systemctl stop ufw.service
systemctl disable ufw.service


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

cephadm bootstrap --mon-ip $IP_FIRST_CEPH_NODE # first server ip

# Add ceph utils
cephadm add-repo --release octopus
cephadm install ceph-common

# TODO Create volume and attached to node (but *dont* mount it)
# See https://docs.ceph.com/en/pacific/cephadm/services/osd/#listing-storage-devices

ceph orch daemon add osd $IP_FIRST_CEPH_NODE:/dev/sdb

# TODO remove pre-formated disk ceph orch osd rm 0
# TODO clean/zap it ceph orch device zap --force ceph-a /dev/vdb

# Verify attached storage is supported by Ceph
# See https://docs.ceph.com/en/latest/cephadm/services/osd/#list-devices
cephadm shell lsmcli ldl

# List disks
ceph orch device ls
# List osds
ceph osd status

ceph status

# Add storage
ceph orch apply osd --all-available-devices

# Deploy a filesystem ontop of the OSDs?
# See https://docs.ceph.com/en/pacific/cephadm/services/mds/#orchestrator-cli-cephfs
#ceph fs volume create <fs_name> --placement="<placement spec>"
#.e.g ceph fs volume create myfs --placement=ceph-a

#!/bin/bash

IP=$1

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

# Add ceph utils
./cephadm add-repo --release octopus
./cephadm install ceph-common


# Verify attached storage is supported by Ceph
# See https://docs.ceph.com/en/latest/cephadm/services/osd/#list-devices
./cephadm shell lsmcli ldl

ceph orch daemon add osd $IP:/dev/vdb
ceph orch daemon add osd $IP:/dev/sdb

# TODO remove pre-formated disk ceph orch osd rm 0
# TODO clean/zap it ceph orch device zap --force ceph-a /dev/vdb


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

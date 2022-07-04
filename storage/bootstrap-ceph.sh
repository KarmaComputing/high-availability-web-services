#!/bin/bash
set -e

IP=$1
sudo -i

ufw disable
systemctl stop ufw.service
systemctl disable ufw.service


. /etc/os-release

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -

apt-get update
apt-get -y upgrade
apt-get -y install podman

# Now bootstrap ceph

curl --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm

chmod +x cephadm

which cephadm

# Add ceph utils
./cephadm add-repo --release quincy
./cephadm install
./cephadm install ceph-common
ceph -v


# Verify attached storage is supported by Ceph
# See https://docs.ceph.com/en/latest/cephadm/services/osd/#list-devices
./cephadm shell lsmcli ldl

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

ceph status

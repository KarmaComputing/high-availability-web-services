#!/bin/sh

set -x

# For each Hetzner server configure the first
# volume /etc/fstab options to be
# valid for TiDB.
# See https://docs.pingcap.com/tidb/stable/check-before-deployment

umount /dev/sdb
mkdir -p /mnt/data1
sed -r -i 's/(.*by-id\/scsi-0HC_Volume.*\/)(.*).*/\1\data1 ext4 defaults,nodelalloc,noatime,nofail 0 0/p' /etc/fstab

cat /etc/fstab | uniq > /etc/fstab.new && cp /etc/fstab.new /etc/fstab 

# -r flag tells sed to use extended regular expressions
# The brackets () are a match group, there is only one match group,
# Which is printed by /1 (if there was a seccond match group, then
# there would be \2 to print it)
# Not the characters .* after the () brackets is *not* a regex, it 
# explicitly tells sed that we want to ignore any number of any type 
# of characters between the defined groups
# -i flag performs edits the file directly
# See: https://www.ryanchapin.com/using-sed-with-regex-capture-groups/

mount -a
mount -t ext4

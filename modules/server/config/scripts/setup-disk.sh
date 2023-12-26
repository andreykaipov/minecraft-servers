#!/bin/sh

set -eu

: "${lun?}"

device=$(lsblk -lo NAME,HCTL | awk -vlun="$lun" -F'[: ]' '$7==lun{print $1}')
if [ -z "$device" ]; then
        echo "No device found for LUN $lun" >&2
        exit 1
fi

part="${device}1"
if ! blkid "/dev/$device"; then
        echo "Formatting /dev/$device"
        wipefs -a "/dev/$device"
        parted "/dev/$device" --script mklabel gpt mkpart ext4part ext4 0% 100%
        yes | mkfs.ext4 "/dev/$part"
        partprobe "/dev/$part"
fi

datadir=/opt/minecraft
mkdir -p "$datadir"
if ! mountpoint -q "$datadir"; then
        echo "Mounting /dev/$part to $datadir"
        mount "/dev/$part" "$datadir"
fi

if ! grep -q "$datadir" /etc/fstab; then
        echo "Adding /dev/$part to /etc/fstab"
        part_uuid=$(blkid -s UUID -o value "/dev/$part")
        echo "UUID=$part_uuid $datadir ext4 defaults,nofail 1 2" >>/etc/fstab
fi

#!/bin/bash
DISK="/dev/sdc"
MOUNTPOINT="/datadisk"

# Partition and format the disk if not already
if ! blkid $DISK; then
  parted $DISK --script mklabel gpt mkpart xfspart xfs 0% 100%
  mkfs.xfs ${DISK}1
fi

# Create mount point
mkdir -p $MOUNTPOINT

# Mount the disk
mount ${DISK}1 $MOUNTPOINT

# Add to fstab to mount on reboot
echo "${DISK}1 $MOUNTPOINT xfs defaults,nofail 0 2" >> /etc/fstab


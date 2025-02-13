#!/bin/bash

set -e  # Exit on error

echo "Listing available disks..."
DISKS=($(lsblk -dpno NAME | grep -E "/dev/sd|/dev/nvme"))
NUM_DISKS=${#DISKS[@]}

# Display disks with numbers
for i in "${!DISKS[@]}"; do
    SIZE=$(lsblk -dn -o SIZE "${DISKS[$i]}")
    echo "$((i+1))) ${DISKS[$i]} - $SIZE"
done

# Ask user to select a disk by number
read -p "Select a disk to format (1-$NUM_DISKS): " CHOICE

# Validate input
if [[ ! "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > NUM_DISKS )); then
    echo "Invalid choice. Exiting."
    exit 1
fi

DISK=${DISKS[$((CHOICE-1))]}

# Confirm with the user
read -p "WARNING: This will erase all data on $DISK. Continue? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 1
fi

# Unmount the disk if it's mounted
echo "Unmounting $DISK..."
sudo umount ${DISK}* 2>/dev/null || true

# Wipe and create a new partition table
echo "Wiping disk and creating a new FAT32 partition..."
sudo parted -s "$DISK" mklabel msdos
sudo parted -s "$DISK" mkpart primary fat32 1MiB 100%
PARTITION="${DISK}1"

# Format the partition as FAT32
echo "Formatting $PARTITION as FAT32..."
sudo mkfs.vfat -F 32 -n "BSYS-UPDATE" "$PARTITION"

# Create a temporary mount point
MOUNT_POINT="/mnt/usb_tmp"
sudo mkdir -p "$MOUNT_POINT"

# Mount the newly formatted partition
echo "Mounting $PARTITION to $MOUNT_POINT..."
sudo mount "$PARTITION" "$MOUNT_POINT"

# Copy files from 'build' directory
echo "Copying files from 'build' directory..."
sudo cp -r build/* "$MOUNT_POINT"

# Sync and unmount
sync
echo "Unmounting $PARTITION..."
sudo umount "$MOUNT_POINT"

echo "Operation completed successfully!"

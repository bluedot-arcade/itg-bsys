#!/bin/bash

set -e  # Exit on error

# Check if the 'build' directory exists and is not empty
if [ ! -d "build" ] || [ -z "$(ls -A build)" ]; then
    echo "Error: 'build' directory not found or empty."
    echo "Hint: Run 'build.sh' first."
    exit 1
fi

# Check if the --all flag is provided
ALL_FLAG=false
if [[ "$1" == "--all" ]]; then
    ALL_FLAG=true
fi

echo "Listing available disks..."
DISKS=($(lsblk -dpno NAME | grep -E "/dev/sd|/dev/nvme"))
NUM_DISKS=${#DISKS[@]}

# Array to store the filtered disks
FILTERED_DISKS=()

# Display disks with numbers, hide disks larger than 100 GB unless --all is used
for i in "${!DISKS[@]}"; do
    SIZE=$(lsblk -dn -o SIZE "${DISKS[$i]}")
    # Remove non-numeric characters (like 'B') and convert to GB
    SIZE_GB=$(echo "$SIZE" | sed 's/[A-Za-z]//g')  # Remove letters like 'B'
    SIZE_GB=$(echo "$SIZE_GB" | awk '{print int($1+0.5)}')  # Round to nearest integer
    
    # Add disk to filtered list if the size is within the limit or --all is used
    if [[ "$ALL_FLAG" == true ]] || (( SIZE_GB <= 100 )); then
        FILTERED_DISKS+=("${DISKS[$i]} - ${SIZE}")
    fi
done

# Display filtered disks
NUM_FILTERED_DISKS=${#FILTERED_DISKS[@]}
for i in "${!FILTERED_DISKS[@]}"; do
    echo "$((i+1))) ${FILTERED_DISKS[$i]}"
done

# Ask user to select a disk by number
read -p "Select a disk to format (1-$NUM_FILTERED_DISKS): " CHOICE

# Validate input
if [[ ! "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > NUM_FILTERED_DISKS )); then
    echo "Invalid choice. Exiting."
    exit 1
fi

# Get the actual disk path from the filtered list
DISK=${FILTERED_DISKS[$((CHOICE-1))]}
DISK=${DISK%% *}  # Remove the size part to get only the disk path

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

#!/bin/bash

FLAG_FILE="/run/itg/update-ready"
MOUNTPOINT="/mnt/update"

create_flag_file() {
    if [[ ! -d "$(dirname "$FLAG_FILE")" ]]; then
        echo "Parent directory does not exist. Creating it..."
        mkdir -p "$(dirname "$FLAG_FILE")"
    fi

    echo "0" > "$FLAG_FILE"
    sudo chown itg:itg "$FLAG_FILE"
    echo "Flag file created at $FLAG_FILE."
    sync
}

cleanup() {
    # Unmount the storage device
    echo "Unmounting device $DEVICE from $MOUNTPOINT..."
    if ! sudo umount "$MOUNTPOINT"; then
        echo "Error: Failed to unmount device $DEVICE from $MOUNTPOINT."
        exit 1
    fi
}

reset_flag() {
   echo "0" > "$FLAG_FILE"
   echo "Flag reset to 0."
   sync
}

# Find a storage device with label "BSYS-UPDATE"
DEVICE=$(lsblk -o NAME,LABEL -l | grep BSYS-UPDATE | awk '{print $1}')

if [[ -z "$DEVICE" ]]; then
    echo "Error: No storage device with label BSYS-UPDATE found."
    reset_flag
    exit 1
fi

echo "Found device: $DEVICE"

# Create mount point if it doesn't exist
if [[ ! -d "$MOUNTPOINT" ]]; then
    echo "Creating mount point: $MOUNTPOINT"
    sudo mkdir -p "$MOUNTPOINT"
fi

# Unmount the storage device if it is already mounted
if mountpoint -q "$MOUNTPOINT"; then
    echo "Unmounting device $DEVICE from $MOUNTPOINT..."
    if ! sudo umount "$MOUNTPOINT"; then
        echo "Error: Failed to unmount device $DEVICE from $MOUNTPOINT."
        exit 1
    fi
fi

# Mount the storage device
echo "Mounting device $DEVICE to $MOUNTPOINT..."
if ! sudo mount "/dev/$DEVICE" "$MOUNTPOINT"; then
    echo "Error: Failed to mount device $DEVICE to $MOUNTPOINT."
    exit 1
fi

# Find the itgmania-bsys .deb package
PACKAGE=$(find "$MOUNTPOINT" -name "itgmania-bsys-*.deb" | head -n 1)

if [[ -z "$PACKAGE" ]]; then
    echo "Error: No itgmania-bsys .deb package found in $MOUNTPOINT."
    cleanup
    exit 1
fi

echo "Found package: $PACKAGE"

# Check if the package is installed and up-to-date
if dpkg-query -W -f='${Version}' itgmania-bsys | grep -q "$(dpkg-deb -f "$PACKAGE" Version)"; then
    echo "Package is already installed and up-to-date."
else 
    if [[ -f "$FLAG_FILE" ]]; then
        create_flag_file
    fi
    echo "1" > "$FLAG_FILE"
    echo "Flag file set to 1." 
    sync
fi

cleanup







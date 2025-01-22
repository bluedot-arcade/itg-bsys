#!/bin/bash

FLAG_FILE="/run/user/1000/itg/update-ready"
MOUNTPOINT="/mnt/update"

cleanup() {
    # Unmount the storage device
    echo "Unmounting device $DEVICE from $MOUNTPOINT..."
    if ! sudo umount "$MOUNTPOINT"; then
        echo "Error: Failed to unmount device $DEVICE from $MOUNTPOINT."
        exit 1
    fi
}

# Find a storage device with label "BSYS-UPDATE"
DEVICE=$(lsblk -o NAME,LABEL -l | grep BSYS-UPDATE | awk '{print $1}')

if [[ -z "$DEVICE" ]]; then
    echo "Error: No storage device with label BSYS-UPDATE found."
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
    cleanup
    exit 0
fi

# Install the package
echo "Installing package $PACKAGE..."
if ! sudo dpkg -i "$PACKAGE"; then
    echo "Error: Failed to install package $PACKAGE."
    cleanup
    exit 1
fi

# Reset the flag file to 0
if [[ -f "$FLAG_FILE" ]]; then
    echo "0" | sudo tee "$FLAG_FILE" > /dev/null
    echo "Flag file set to 0." 
    sync
else 
    echo "Error: $FLAG_FILE does not exist."
    cleanup
    exit 1
fi

cleanup

# Check for --restart-game parameter
if [[ "$1" == "--restart-game" ]]; then
    echo "Restarting game..."
    if ! systemctl --user start itgmania.service; then
        echo "Error: Failed to restart game."
        exit 1
    fi
    echo "Game restarted successfully."
fi






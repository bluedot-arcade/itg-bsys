#!/bin/bash

DEFAULTS_DIR="/opt/itgmania/Defaults"
DEST_DIR="/mnt/data/itgmania"

run_user_systemctl() {
    echo "Running user systemctl command: systemctl --user -M itg@ $@"
    if ! sudo systemctl --user -M itg@ "$@"; then
        echo "ERROR: Failed to run systemctl --user -M itg@ $@"
        exit 1
    fi
}

# Stop the itgmania service
run_user_systemctl stop itgmania.service

# Check if the Defaults directory exists
if [[ ! -d "$DEFAULTS_DIR" ]]; then
    echo "Error: $DEFAULTS_DIR does not exist."
    exit 1
fi

# Check if the destination directory exists
if [[ ! -d "$DEST_DIR" ]]; then
    echo "Error: $DEST_DIR does not exist."
    exit 1
fi

# Copy the files from the Defaults directory to the destination directory
echo "Copying files from $DEFAULTS_DIR to $DEST_DIR..."
cp -r "$DEFAULTS_DIR"/* "$DEST_DIR"

# Check if the copy was successful
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to copy files."
    exit 1
fi

echo "Files copied successfully."


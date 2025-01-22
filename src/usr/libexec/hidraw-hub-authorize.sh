#!/bin/bash

# Define variables
HIDRAW_DEVICE="$1"
SERVICE_MODE_ENABLED_FILE="/run/user/1000/itg/service-mode-enabled"

# Parse command line options
UNAUTHORIZE=0
if [[ "$2" == "--unauthorize" ]]; then
    UNAUTHORIZE=1
fi

# Get hidraw device path
HIDRAW_DEVICE_PATH=$(realpath "/sys/class/hidraw/$HIDRAW_DEVICE")

# Get parent usb device path
USB_DEVICE_PATH=$(realpath "$HIDRAW_DEVICE_PATH/../../..")

# Check if the authorized attribute exists
if [ -w "$USB_DEVICE_PATH/authorized" ]; then
    if [ "$UNAUTHORIZE" -eq 1 ]; then
        # If --unauthorize is passed, simply unauthorize the device
        echo 0 > "$USB_DEVICE_PATH/authorized"
        echo "Device $HIDRAW_DEVICE has been unauthorized."
    else
        # Read the service mode enabled flag
        if [ -f "$SERVICE_MODE_ENABLED_FILE" ]; then
            SERVICE_MODE_ENABLED=$(cat "$SERVICE_MODE_ENABLED_FILE")
        else
            SERVICE_MODE_ENABLED=0  # Default to unauthorized if file is missing
        fi

        # Authorize only when service mode is enabled
        if [ "$SERVICE_MODE_ENABLED" -eq 1 ]; then
            echo 1 > "$USB_DEVICE_PATH/authorized"
            echo "Device $HIDRAW_DEVICE has been authorized in service mode."
        else
            echo 0 > "$USB_DEVICE_PATH/authorized"
            echo "Device $HIDRAW_DEVICE is not authorized, service mode not enabled."
        fi
    fi
else
    echo "Error: Unable to access the authorized attribute for $HIDRAW_DEVICE."
    exit 1
fi

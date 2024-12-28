#!/bin/bash

# Path to the monitored file
FLAG_FILE="/var/local/itg-stop"

reset_flag() {
   echo "0" > "$FLAG_FILE"
   echo "Flag reset to 0."
   sync
}

# Read the content of the file
if [[ -f "$FLAG_FILE" ]]; then
    CONTENT=$(cat "$FLAG_FILE")

    if [[ "$CONTENT" == "1" ]]; then
        echo "Stopping itgmania.service..."
        systemctl --user stop itgmania.service
    fi

    reset_flag
else
    echo "Error: $FLAG_FILE does not exist."
    exit 1
fi

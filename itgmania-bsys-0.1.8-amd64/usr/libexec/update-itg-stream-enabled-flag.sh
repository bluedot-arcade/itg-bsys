#!/bin/bash

FLAG_FILE="/var/local/itg-stream-enabled"
SERVICE="obs-streaming.service"
WATCHER="obs-streaming-watcher.path"

reset_flag() {
    echo "0" > "$FLAG_FILE"
    echo "Flag reset to 0."
    sync
}

if [[ -f "$FLAG_FILE" ]]; then
    CONTENT=$(cat "$FLAG_FILE")

    if [[ "$CONTENT" == "1" ]]; then
        # Check if the service is already active
        if ! systemctl --user is-active --quiet "$SERVICE"; then
            echo "Service $SERVICE is not active. Starting it..."
            systemctl --user start "$SERVICE"
        else
            echo "Service $SERVICE is already active."
        fi
    elif [[ "$CONTENT" == "0" ]]; then
        # Check if the service is already inactive
        if systemctl --user is-active --quiet "$SERVICE"; then
            echo "Service $SERVICE is active. Stopping it..."
            systemctl --user stop "$SERVICE"
        else
            echo "Service $SERVICE is already inactive."
        fi
    else
        echo "Invalid flag content: $CONTENT. It must be either 0 or 1."
        exit 1
    fi

    # Update the flag file to reflect the current state
    if systemctl --user is-active --quiet "$SERVICE"; then
        systemctl --user stop "$WATCHER"
        echo "1" > "$FLAG_FILE"
        echo "Flag set to 1, service is active."
        sync
        systemctl --user start "$WATCHER"
    else
        systemctl --user stop "$WATCHER"
        echo "0" > "$FLAG_FILE"
        echo "Flag set to 0, service is inactive."
        sync
        systemctl --user start "$WATCHER"
    fi
else
    echo "Error: $FLAG_FILE does not exist."
    exit 1
fi

#!/bin/bash

USER_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
FLAG_FILE="$USER_RUNTIME_DIR/itg/itg-stream-enabled"
SERVICE="obs-streaming.service"
WATCHER="obs-streaming-watcher.path"

create_flag_file() {
    if [[ ! -d "$(dirname "$FLAG_FILE")" ]]; then
        echo "Parent directory does not exist. Creating it..."
        mkdir -p "$(dirname "$FLAG_FILE")"
    fi

    echo "0" > "$FLAG_FILE"
    echo "Flag file created at $FLAG_FILE."
    sync
}

reset_flag() {
    echo "0" > "$FLAG_FILE"
    echo "Flag reset to 0."
    sync
}

set_flag() {
    echo "1" > "$FLAG_FILE"
    echo "Flag set to 1."
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
        set_flag
        systemctl --user start "$WATCHER"
    else
        systemctl --user stop "$WATCHER"
        reset_flag
        systemctl --user start "$WATCHER"
    fi
else
    echo "Flag file does not exist. Creating it at $FLAG_FILE..."
    create_flag_file
fi

#!/bin/bash

USER_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
FLAG_FILE="$USER_RUNTIME_DIR/itg/update"
UPDATE_SCRIPT="/usr/libexec/do-update-from-media.sh"

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

update() {
    echo "Running update script..."
    $UPDATE_SCRIPT
}

# Read the content of the file
if [[ -f "$FLAG_FILE" ]]; then
    CONTENT=$(cat "$FLAG_FILE")

    if [[ "$CONTENT" == "1" ]]; then
        update
    fi

    reset_flag
else
    echo "Flag file does not exist. Creating it at $FLAG_FILE..."
    create_flag_file
fi


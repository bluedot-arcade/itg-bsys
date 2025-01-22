#!/bin/bash

FLAG_FILE="/run/user/1000/itg/itg-stop"

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

stop_game() {
    echo "Stopping itgmania.service..."
    systemctl --user stop itgmania.service
}

if [[ -f "$FLAG_FILE" ]]; then
    CONTENT=$(cat "$FLAG_FILE")
    if [[ "$CONTENT" == "1" ]]; then
        stop_game
    fi

    reset_flag
else
    echo "Flag file does not exist. Creating it at $FLAG_FILE..."
    create_flag_file
fi

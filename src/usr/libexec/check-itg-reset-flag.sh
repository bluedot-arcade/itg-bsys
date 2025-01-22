#!/bin/bash

FLAG_FILE="/run/user/1000/itg/itg-reset"
RESET_SCRIPT="/usr/libexec/itg-reset-to-defaults.sh"

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

reset_game() {
    echo "Resetting itgmania to default settings..."
    $RESET_SCRIPT
}

if [[ -f "$FLAG_FILE" ]]; then
    CONTENT=$(cat "$FLAG_FILE")
    if [[ "$CONTENT" == "1" ]]; then
        reset_game
    fi

    reset_flag
else
    echo "Flag file does not exist. Creating it at $FLAG_FILE..."
    create_flag_file
fi

#!/bin/bash

FLAG_FILE="/run/user/1000/itg/os-restart"

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

reset_flag() {
   echo "0" > "$FLAG_FILE"
   echo "Flag reset to 0."
   sync
}

restart_os() {
    echo "Restarting OS..."
    reboot
}

if [[ -f "$FLAG_FILE" ]]; then
    CONTENT=$(cat "$FLAG_FILE")

    if [[ "$CONTENT" == "1" ]]; then
        restart_os
    fi

    reset_flag
else
    echo "Flag file does not exist. Creating it at $FLAG_FILE..."
    create_flag_file
fi


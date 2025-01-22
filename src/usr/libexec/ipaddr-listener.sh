#!/bin/bash

IP_FILE="/run/user/1000/itg/ipaddr"
CHECK_INTERVAL=5  # Time in seconds to wait between each check for IP address changes

get_current_ips() {
    ip -o -4 addr show | awk '{if ($3 != "lo") print $2 "=" $4}' | cut -d'/' -f1
}

CURRENT_IPS=$(get_current_ips)

if [[ ! -f "$IP_FILE" ]]; then
    # If the file doesn't exist, create it and write the initial IP addresses with interface names
    echo "$CURRENT_IPS" > "$IP_FILE"
    echo "Initial IP addresses set:"
    echo "$CURRENT_IPS"
else
    LAST_IPS=$(cat "$IP_FILE")

    # If the IP addresses have changed, update the file
    if [[ "$CURRENT_IPS" != "$LAST_IPS" ]]; then
        echo "$CURRENT_IPS" > "$IP_FILE"
        echo "IP addresses updated:"
        echo "$CURRENT_IPS"
    fi
fi

while true; do
    CURRENT_IPS=$(get_current_ips)
    LAST_IPS=$(cat "$IP_FILE")

    # If the IP addresses have changed, update the file
    if [[ "$CURRENT_IPS" != "$LAST_IPS" ]]; then
        echo "$CURRENT_IPS" > "$IP_FILE"
        echo "IP addresses updated:"
        echo "$CURRENT_IPS"
    fi

    sleep "$CHECK_INTERVAL"
done

#!/bin/bash

IP_FILE="/run/user/1000/itg/ipaddr"
CHECK_INTERVAL=20  # Time in seconds to wait between each check for IP address changes
BNET_SERVER_IP="10.0.0.1"
BNET_SERVER_PING_TIMEOUT=2

get_current_ips() {
    ip -o -4 addr show | awk '{if ($3 != "lo") print $2 "=" $4}' | cut -d'/' -f1
}

CURRENT_IPS=$(get_current_ips)

if [[ ! -f "$IP_FILE" ]]; then
    echo "$CURRENT_IPS" > "$IP_FILE"
    echo "Initial IP addresses set:"
    echo "$CURRENT_IPS"
else
    LAST_IPS=$(cat "$IP_FILE")

    if [[ "$CURRENT_IPS" != "$LAST_IPS" ]]; then
        echo "$CURRENT_IPS" > "$IP_FILE"
        echo "IP addresses updated:"
        echo "$CURRENT_IPS"
    fi
fi

while true; do
    CURRENT_IPS=$(get_current_ips)
    LAST_IPS=$(cat "$IP_FILE")

    if [[ "$CURRENT_IPS" != "$LAST_IPS" ]]; then
        echo "$CURRENT_IPS" > "$IP_FILE"
        echo "IP addresses updated:"
        echo "$CURRENT_IPS"
    fi

    # Check if connected to Bnet VPN server.
    if ! ping -c 1 -W "$BNET_SERVER_PING_TIMEOUT" "$BNET_SERVER_IP" &>/dev/null; then
        sed -i '/^bnet0=/d' "$IP_FILE"
    fi

    sleep "$CHECK_INTERVAL"
done
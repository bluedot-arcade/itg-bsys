#!/bin/bash
# Usage: set_fixed_volume.sh <0-100> [center-audio-balance]
#   center-audio-balance: omit or pass any value except "false" to center channels

VOLUME="$1"
CENTER="${2}"

# Get default sink
SINK=$(pactl info | grep "Default Sink" | awk '{print $3}')

if [ -z "$SINK" ]; then
    echo "Error: Could not determine default sink."
    exit 1
fi

# Set volume and unmute
if [ "$CENTER" = "false" ]; then
    pactl set-sink-volume "$SINK" "${VOLUME}%"
    echo "Audio set to ${VOLUME}% on sink: $SINK"
else
    pactl set-sink-volume "$SINK" "${VOLUME}%" "${VOLUME}%"
    echo "Audio set to ${VOLUME}% (centered) on sink: $SINK"
fi
pactl set-sink-mute "$SINK" 0
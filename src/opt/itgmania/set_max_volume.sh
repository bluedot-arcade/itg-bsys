# Get default sink
SINK=$(pactl info | grep "Default Sink" | awk '{print $3}')

if [ -z "$SINK" ]; then
    echo "Error: Could not determine default sink."
    exit 1
fi

# Set master volume to 100%
pactl set-sink-volume "$SINK" 100%

# Set left and right channels equally (centered)
pactl set-sink-volume "$SINK" 100% 100%  # left right

# Optional: unmute
pactl set-sink-mute "$SINK" 0

echo "Audio set to max and centered on sink: $SINK"
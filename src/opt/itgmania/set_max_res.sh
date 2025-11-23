#!/bin/bash

# Check if xrandr is installed
if ! command -v xrandr &> /dev/null; then
    echo "Error: xrandr is not installed."
    exit 1
fi

# Get the first connected display
DISPLAY_NAME=$(xrandr | grep " connected" | awk '{print $1}' | head -n 1)

if [ -z "$DISPLAY_NAME" ]; then
    echo "Error: No connected monitor found."
    exit 1
fi

echo "Detected Monitor: $DISPLAY_NAME"

# Get all modes for the display in the format WIDTH HEIGHT RATE
MODES=$(xrandr | sed -n "/^$DISPLAY_NAME connected/,/[a-zA-Z]/p" \
| grep -E "^   [0-9]+" \
| awk '{
    split($1, res, "x");
    width = res[1];
    height = res[2];
    for (i=2; i<=NF; i++) {
        rate = $i;
        gsub(/[i+*+]/, "", rate);
        print width, height, rate;
    }
}')

if [ -z "$MODES" ]; then
    echo "Error: No modes found."
    exit 1
fi

# Sort by resolution first, then refresh rate (all descending)
TARGET_CONFIG=$(echo "$MODES" | sort -k1,1nr -k2,2nr -k3,3nr | head -n 1)

# Extract values
BEST_WIDTH=$(echo "$TARGET_CONFIG" | awk '{print $1}')
BEST_HEIGHT=$(echo "$TARGET_CONFIG" | awk '{print $2}')
BEST_RATE=$(echo "$TARGET_CONFIG" | awk '{print $3}')

echo "Applying mode: ${BEST_WIDTH}x${BEST_HEIGHT} at ${BEST_RATE}Hz..."

# Apply the mode
xrandr --output "$DISPLAY_NAME" --mode "${BEST_WIDTH}x${BEST_HEIGHT}" --rate "$BEST_RATE" && \
echo "Success! Mode set."

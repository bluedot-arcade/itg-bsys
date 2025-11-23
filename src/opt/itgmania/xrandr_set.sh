#!/bin/bash

# Default priority
PRIORITY="resolution"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --set-max-res) PRIORITY="resolution" ;;
        --set-max-rate) PRIORITY="rate" ;;
        *) echo "Unknown parameter: $1"; echo "Usage: $0 [--set-max-res | --set-max-rate]"; exit 1 ;;
    esac
    shift
done

# Check if xrandr is installed
if ! command -v xrandr &> /dev/null; then
    echo "Error: xrandr is not installed."
    exit 1
fi

# Get the first connected display
# We grep for " connected" and take the first word of the first line found.
DISPLAY_NAME=$(xrandr | grep " connected" | awk '{print $1}' | head -n 1)

if [ -z "$DISPLAY_NAME" ]; then
    echo "Error: No connected monitor found."
    exit 1
fi

echo "Detected Monitor: $DISPLAY_NAME"

# Determine sort order based on priority
if [ "$PRIORITY" == "resolution" ]; then
    # Sort by Width (1), Height (2), then Rate (3) - all descending
    SORT_OPTS="-k1,1nr -k2,2nr -k3,3nr"
    echo "Mode: Prioritizing Maximum Resolution..."
else
    # Sort by Rate (3), then Width (1), then Height (2) - all descending
    SORT_OPTS="-k3,3nr -k1,1nr -k2,2nr"
    echo "Mode: Prioritizing Maximum Refresh Rate..."
fi

# 1. Get xrandr output for the specific display
# 2. Parse lines that start with whitespace (which contains the modes)
# 3. Clean up formatting (remove * and + markers from refresh rates)
# 4. Unroll the data so every rate is on its own line: "WIDTH HEIGHT RATE"
# 5. Sort based on the SORT_OPTS defined above
# 6. Take the top result

TARGET_CONFIG=$(xrandr | sed -n "/^$DISPLAY_NAME connected/,/[a-zA-Z]/p" \
| grep -E "^   [0-9]+" \
| awk '{
    # Extract Resolution (e.g., 1920x1080)
    split($1, res, "x");
    width = res[1];
    height = res[2];

    # Iterate through all remaining columns (refresh rates)
    for (i=2; i<=NF; i++) {
        rate = $i;
        # Remove "i" (interlaced), "+" (preferred), "*" (current)
        gsub(/[i+*]/, "", rate); 
        print width, height, rate;
    }
}' \
| sort $SORT_OPTS \
| head -n 1)

# Extract the values found
BEST_WIDTH=$(echo "$TARGET_CONFIG" | awk '{print $1}')
BEST_HEIGHT=$(echo "$TARGET_CONFIG" | awk '{print $2}')
BEST_RATE=$(echo "$TARGET_CONFIG" | awk '{print $3}')

if [ -z "$BEST_WIDTH" ] || [ -z "$BEST_RATE" ]; then
    echo "Error: Could not determine optimal mode."
    exit 1
fi

echo "Applying target mode: ${BEST_WIDTH}x${BEST_HEIGHT} at ${BEST_RATE}Hz..."

# Apply the mode
xrandr --output "$DISPLAY_NAME" --mode "${BEST_WIDTH}x${BEST_HEIGHT}" --rate "$BEST_RATE"

if [ $? -eq 0 ]; then
    echo "Success! Mode set."
else
    echo "Error: Failed to apply mode."
fi
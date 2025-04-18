#!/bin/bash

CONFIG_FILE="/mnt/data/itgmania/Save/Startup.ini"

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<EOL
[Options]
service-mode-on-exit=true

[Gamescope]
enabled=true
auto-resolution=true
auto-refreshrate=true
resolution-width=1920
resolution-height=1080
refresh-rate=60
realtime-mode=true
EOL
    echo "Created default Startup.ini configuration."
fi

# Wait for the display server to be available (Xwayland or X11)
for i in {1..10}; do
    if xrandr > /dev/null 2>&1; then
        break
    fi
    echo "Waiting for display server..."
    sleep 1
done

# Read settings from Startup.ini using grep and sed to avoid picking up the wrong line
SERVICE_MODE_ON_EXIT=$(grep -m1 -oP '^service-mode-on-exit=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
GAMESCOPE_ENABLED=$(grep -m1 -oP '^enabled=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
AUTO_RESOLUTION=$(grep -m1 -oP '^auto-resolution=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
AUTO_REFRESHRATE=$(grep -m1 -oP '^auto-refreshrate=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
RESOLUTION_W=$(grep -m1 -oP '^resolution-width=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
RESOLUTION_H=$(grep -m1 -oP '^resolution-height=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
REFRESH_RATE=$(grep -m1 -oP '^refresh-rate=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
REALTIME_MODE=$(grep -m1 -oP '^realtime-mode=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')

# Auto-detect resolution if enabled
if [ "$AUTO_RESOLUTION" == "true" ]; then
    RESOLUTION=$(xrandr | grep '*' | awk '{print $1}' | head -n1)
    RESOLUTION_W=${RESOLUTION%x*}
    RESOLUTION_H=${RESOLUTION#*x}
fi

# Auto-detect refresh rate if enabled
if [ "$AUTO_REFRESHRATE" == "true" ]; then
    REFRESH_RATE=$(xrandr | grep '*' | awk '{print $2}' | head -n1 | cut -d'.' -f1)
fi

# Print detected or configured values
echo "Resolution: ${RESOLUTION_W}x${RESOLUTION_H}"
echo "Refresh Rate: ${REFRESH_RATE}Hz"

# Start ITGMania with Gamescope if enabled
if [ "$GAMESCOPE_ENABLED" == "true" ]; then
    echo "Starting ITGMania with Gamescope..."
    GAMESCOPE_CMD="gamescope -r $REFRESH_RATE -w $RESOLUTION_W -h $RESOLUTION_H -f"
    
    # Add real-time mode if enabled
    if [ "$REALTIME_MODE" == "true" ]; then
        GAMESCOPE_CMD+=" --rt"
    fi
    
    # Debug: Print the final gamescope command before execution
    echo "Gamescope command: $GAMESCOPE_CMD"
    
    # Run the final gamescope command with ITGMania
    $GAMESCOPE_CMD -- /opt/itgmania/itgmania
else
    echo "Starting ITGMania without Gamescope..."
    /opt/itgmania/itgmania
fi

# Run service-mode-enable if enabled in config
if [ "$SERVICE_MODE_ON_EXIT" == "true" ]; then
    echo "Enabling service mode on exit..."
    /usr/bin/service-mode-enable
fi

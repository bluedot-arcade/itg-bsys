#!/bin/bash

CONFIG_FILE="/mnt/data/itgmania/Save/Startup.ini"
PREFERENCES_FILE="/mnt/data/itgmania/Save/Preferences.ini"

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<EOL
[Options]
service-mode-on-exit=true
windowed-borderless=false
mangohud=false
gamemode=true
allow-vsync=true

[Gamescope]
enabled=false
auto-resolution=true
auto-refreshrate=true
resolution-width=1920
resolution-height=1080
refresh-rate=60
realtime-mode=true
EOL
    echo "Created default Startup.ini configuration."
fi

# Wait for the display server to be available, but only if on X11
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    for i in {1..10}; do
        if xrandr >/dev/null 2>&1; then
            break
        fi
        echo "Waiting for X11 display server..."
        sleep 1
    done
else
    echo "Running on non-X11 session ($XDG_SESSION_TYPE), skipping wait for X server."
fi

# Preferences.ini patching
echo "Checking for $PREFERENCES_FILE..."
if [ -f "$PREFERENCES_FILE" ]; then
    if grep -q '^CurrentGame=dance' "$PREFERENCES_FILE"; then
        echo "CurrentGame is already set to 'dance'. No changes needed."
    else
        sed -i 's/^CurrentGame=.*/CurrentGame=dance/' "$PREFERENCES_FILE"
        echo "Updated CurrentGame to 'dance' in Preferences.ini."
    fi
else
    echo "Preferences.ini not found. Skipping game setting modification."
fi

# Read settings from Startup.ini
SERVICE_MODE_ON_EXIT=$(grep -m1 -oP '^service-mode-on-exit=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
WINDOWED_BORDERLESS=$(grep -m1 -oP '^windowed-borderless=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
MANGOHUD_ENABLED=$(grep -m1 -oP '^mangohud=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
GAMEMODE_ENABLED=$(grep -m1 -oP '^gamemode=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
ALLOW_VSYNC=$(grep -m1 -oP '^allow-vsync=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
GAMESCOPE_ENABLED=$(grep -m1 -oP '^enabled=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
AUTO_RESOLUTION=$(grep -m1 -oP '^auto-resolution=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
AUTO_REFRESHRATE=$(grep -m1 -oP '^auto-refreshrate=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
RESOLUTION_W=$(grep -m1 -oP '^resolution-width=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
RESOLUTION_H=$(grep -m1 -oP '^resolution-height=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
REFRESH_RATE=$(grep -m1 -oP '^refresh-rate=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')
REALTIME_MODE=$(grep -m1 -oP '^realtime-mode=\K.*' "$CONFIG_FILE" | tr -d '[:space:]')

# Auto-detect resolution and refresh rate
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    if [ "$AUTO_RESOLUTION" = "true" ]; then
        RESOLUTION=$(xrandr | grep '*' | awk '{print $1}' | head -n1)
        RESOLUTION_W=${RESOLUTION%x*}
        RESOLUTION_H=${RESOLUTION#*x}
    fi
    if [ "$AUTO_REFRESHRATE" = "true" ]; then
        REFRESH_RATE=$(xrandr | grep '*' | awk '{print $2}' | head -n1 | cut -d'.' -f1)
    fi
else
    echo "Running on non-X11 session ($XDG_SESSION_TYPE), skipping auto-detection of resolution and refresh rate."
    if [ "$AUTO_RESOLUTION" = "true" ]; then
        RESOLUTION_W=""
        RESOLUTION_H=""
    fi
    if [ "$AUTO_REFRESHRATE" = "true" ]; then
        REFRESH_RATE=""
    fi
fi

# Print detected or configured values
echo "Configuration loaded from $CONFIG_FILE"
echo "Service Mode on Exit: $SERVICE_MODE_ON_EXIT"
echo "Windowed Borderless: $WINDOWED_BORDERLESS"
echo "MangoHud Enabled: $MANGOHUD_ENABLED"
echo "Gamemode Enabled: $GAMEMODE_ENABLED"
echo "Allow VSync: $ALLOW_VSYNC"
echo "Gamescope Enabled: $GAMESCOPE_ENABLED"
echo "  Auto Resolution: $AUTO_RESOLUTION"
echo "  Auto Refresh Rate: $AUTO_REFRESHRATE"
echo "  Resolution Width: $RESOLUTION_W"
echo "  Resolution Height: $RESOLUTION_H"
echo "  Refresh Rate: $REFRESH_RATE"
echo "  Realtime Mode: $REALTIME_MODE"

# Start ITGMania with Gamescope if enabled
if [ "$GAMESCOPE_ENABLED" = "true" ]; then
    echo "Starting ITGMania with Gamescope..."
    GAMESCOPE_CMD="gamescope"

    # Add windowed borderless or fullscreen option
    if [ "$WINDOWED_BORDERLESS" = "true" ]; then
        GAMESCOPE_CMD+=" -b"
    else
        GAMESCOPE_CMD+=" -f"
    fi

    # Add resolution/refresh only if available
    [ -n "$RESOLUTION_W" ] && [ -n "$RESOLUTION_H" ] && GAMESCOPE_CMD+=" -w $RESOLUTION_W -h $RESOLUTION_H -W $RESOLUTION_W -H $RESOLUTION_H"
    [ -n "$REFRESH_RATE" ] && GAMESCOPE_CMD+=" -r $REFRESH_RATE"

    # Add real-time mode if enabled
    [ "$REALTIME_MODE" = "true" ] && GAMESCOPE_CMD+=" --rt"

    # Debug: Print the final gamescope command before execution
    echo "Gamescope command: $GAMESCOPE_CMD"

    # Run gamescope with ITGMania
    if [ "$MANGOHUD_ENABLED" = "true" ]; then
        echo "Starting ITGMania with MangoHud under Gamescope..."
        $GAMESCOPE_CMD -- mangohud /opt/itgmania/itgmania
    else 
        echo "Starting ITGMania under Gamescope..."
        $GAMESCOPE_CMD -- /opt/itgmania/itgmania
    fi
else
    # Stop/start devilspie2 as needed
    if [ "$WINDOWED_BORDERLESS" = "true" ]; then
        echo "Restarting devilspie2 service..."
        systemctl --user restart devilspie2.service
    else
        echo "Stopping devilspie2 service..."
        systemctl --user stop devilspie2.service
    fi

    ITGMANIA_CMD="/opt/itgmania/itgmania"
    if [ "$MANGOHUD_ENABLED" = "true" ]; then
        echo "Starting ITGMania with MangoHud..."
        ITGMANIA_CMD="mangohud $ITGMANIA_CMD"
    fi

    if [ "$GAMEMODE_ENABLED" = "true" ]; then
        echo "Starting ITGMania with Gamemode..."
        ITGMANIA_CMD="gamemoderun $ITGMANIA_CMD"
    fi

    if [ "$ALLOW_VSYNC" = "false" ]; then
        echo "Forcing VSync off..."
        echo "Running: __GL_SYNC_TO_VBLANK=0 vblank_mode=0 $ITGMANIA_CMD"
        __GL_SYNC_TO_VBLANK=0 vblank_mode=0 $ITGMANIA_CMD
    else
        echo "Running: $ITGMANIA_CMD"
        $ITGMANIA_CMD
    fi
fi

# Run service-mode-enable if enabled in config
if [ "$SERVICE_MODE_ON_EXIT" = "true" ]; then
    echo "Enabling service mode on exit..."
    /usr/bin/service-mode-enable
fi

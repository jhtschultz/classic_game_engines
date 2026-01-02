#!/bin/bash
#
# Template start script for Wine + noVNC game servers
#
# Replace placeholders:
#   - GAME_EXE: Path to the game executable in Wine
#
set -euo pipefail

export DISPLAY="${DISPLAY:-:0}"
export NOVNC_LISTEN="${NOVNC_LISTEN:-6080}"
export WINEPREFIX="${WINEPREFIX:-/opt/game/wineprefix}"
export WINEARCH="${WINEARCH:-win64}"

# === CUSTOMIZE: Set path to your game executable ===
GAME_EXE="${WINEPREFIX}/drive_c/Game/game.exe"

if [[ ! -f "$GAME_EXE" ]]; then
    echo "Game executable not found at ${GAME_EXE}" >&2
    exit 1
fi

# Clean up all child processes on exit
trap 'kill 0' EXIT

# Ensure nginx log directory exists
mkdir -p /var/log/nginx

# Start virtual display
Xvfb "$DISPLAY" -screen 0 1280x720x24 &
sleep 2

# Start window manager
fluxbox &
sleep 1

# Launch the game
env WINEPREFIX="$WINEPREFIX" WINEARCH="$WINEARCH" wine64 start /unix "$GAME_EXE" &

# Start VNC server (localhost only - nginx handles external access)
x11vnc -display "$DISPLAY" -localhost -shared -forever -rfbport 5900 -nopw &

# Start WebSocket-to-VNC bridge
websockify "$NOVNC_LISTEN" localhost:5900 &

# Start nginx (foreground - main process)
nginx -g "daemon off;"

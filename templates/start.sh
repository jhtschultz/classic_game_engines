#!/bin/bash
#
# Template start script for game engine servers
#
# Launches: Xvfb → fluxbox → game → x11vnc → websockify → ttyd → nginx
#
set -euo pipefail

export DISPLAY="${DISPLAY:-:0}"
export NOVNC_LISTEN="${NOVNC_LISTEN:-6080}"
export TTYD_PORT="${TTYD_PORT:-7681}"
export PATH="/usr/games:${PATH}"

# === CUSTOMIZE: Set path to your game executable ===
# For native Linux apps:
# GAME_CMD="your-game"
#
# For Windows apps via Wine:
# GAME_CMD="wine64 ${WINEPREFIX}/drive_c/Game/game.exe"

# Clean up all child processes on exit
trap 'kill 0' EXIT

# Ensure runtime directories exist
mkdir -p /var/log/nginx

# Start virtual display
Xvfb "$DISPLAY" -screen 0 1280x800x24 &
sleep 2

# Start window manager
fluxbox &
sleep 1

# === CUSTOMIZE: Launch your game ===
# $GAME_CMD &

# Start VNC server (localhost only - nginx handles external access)
x11vnc -display "$DISPLAY" -localhost -shared -forever -rfbport 5900 -nopw &

# Start WebSocket-to-VNC bridge
websockify "$NOVNC_LISTEN" localhost:5900 &

# Start ttyd web terminal (accessible at /shell/)
ttyd -p "$TTYD_PORT" -i 127.0.0.1 --check-origin bash &

# === OPTIONAL: Start API server ===
# If you have a Flask/FastAPI backend:
# gunicorn -b 127.0.0.1:8081 app.main:app &

# Start nginx (foreground - main process)
nginx -g "daemon off;"

# syntax=docker/dockerfile:1
#
# Template Dockerfile for Windows game engines via Wine + noVNC
#
# Replace placeholders:
#   - YOUR_GAME_NAME: Display name of the game
#   - YOUR_GAME_EXE: Name of the executable
#   - YOUR_GAME_URL: Download URL for the installer (if applicable)
#
# Build: docker build -t your-game-server .
# Run:   docker run --rm -p 8080:8080 your-game-server

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    DISPLAY=:0 \
    NOVNC_LISTEN=6080 \
    WINEPREFIX=/opt/game/wineprefix \
    WINEARCH=win64

# Optional: Download URL for the game installer
# ARG GAME_URL="https://example.com/game_setup.exe"

# Enable 32-bit architecture (some games need it)
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        xvfb \
        fluxbox \
        x11vnc \
        websockify \
        nginx \
        procps \
        curl \
        ca-certificates \
        git \
        wine \
        wine32 \
        wine64 \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

# Clone noVNC from GitHub (Debian packages have websocket compatibility issues)
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC

# Initialize Wine prefix
RUN mkdir -p "${WINEPREFIX}" \
    && xvfb-run -a env WINEPREFIX="${WINEPREFIX}" WINEARCH="${WINEARCH}" wineboot --init \
    && sleep 5

# === CUSTOMIZE: Install your game here ===
# Option 1: Download and run installer
# RUN curl -L "${GAME_URL}" -o /tmp/setup.exe \
#     && xvfb-run -a env WINEPREFIX="${WINEPREFIX}" wine64 /tmp/setup.exe /VERYSILENT \
#     && rm /tmp/setup.exe

# Option 2: Copy pre-downloaded game files
# COPY game-files/ "${WINEPREFIX}/drive_c/Game/"

WORKDIR /app

COPY start.sh /app/start.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY fluxbox.menu /root/.fluxbox/menu

RUN chmod +x /app/start.sh

EXPOSE 8080

ENTRYPOINT ["/app/start.sh"]

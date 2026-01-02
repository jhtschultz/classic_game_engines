# syntax=docker/dockerfile:1
#
# Template Dockerfile for game engines via noVNC
#
# Works for both:
#   - Native Linux apps (no Wine needed)
#   - Windows apps via Wine
#
# Replace placeholders:
#   - YOUR_GAME: Name of the game/engine
#
# Build: gcloud builds submit --tag gcr.io/PROJECT/your-game-server --timeout=30m
# Run:   docker run --rm -p 8080:8080 your-game-server

FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    DISPLAY=:0 \
    NOVNC_LISTEN=6080 \
    TTYD_PORT=7681

ARG TTYD_VERSION=1.7.7

# === BASE PACKAGES ===
# Core VNC stack + common dependencies
RUN apt-get update \
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
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

# Clone noVNC from GitHub (REQUIRED - Debian apt packages have websocket issues)
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC

# Install ttyd for web terminal at /shell/
RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
        amd64) ttyd_asset="ttyd.x86_64" ;; \
        arm64) ttyd_asset="ttyd.aarch64" ;; \
        *) echo "Unsupported architecture: $arch" && exit 1 ;; \
    esac \
    && curl -L -o /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/${ttyd_asset}" \
    && chmod +x /usr/local/bin/ttyd

# === OPTIONAL: WINE (for Windows apps) ===
# Uncomment this section if your game is a Windows executable
#
# RUN dpkg --add-architecture i386 \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends \
#         wine \
#         wine32 \
#         wine64 \
#     && rm -rf /var/lib/apt/lists/*
#
# ENV WINEPREFIX=/opt/game/wineprefix \
#     WINEARCH=win64
#
# RUN mkdir -p "${WINEPREFIX}" \
#     && xvfb-run -a env WINEPREFIX="${WINEPREFIX}" WINEARCH="${WINEARCH}" wineboot --init \
#     && sleep 5

# === CUSTOMIZE: Install your game/engine here ===
#
# For native Linux apps:
# RUN apt-get update && apt-get install -y your-game && rm -rf /var/lib/apt/lists/*
#
# For Windows apps (with Wine section uncommented):
# RUN curl -L "https://example.com/setup.exe" -o /tmp/setup.exe \
#     && xvfb-run -a env WINEPREFIX="${WINEPREFIX}" wine64 /tmp/setup.exe /VERYSILENT \
#     && rm /tmp/setup.exe

WORKDIR /app

# Copy configuration files
COPY start.sh /app/start.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY fluxbox.menu /root/.fluxbox/menu

RUN chmod +x /app/start.sh \
    && mkdir -p /root/.fluxbox /var/log/nginx

EXPOSE 8080

ENTRYPOINT ["/app/start.sh"]

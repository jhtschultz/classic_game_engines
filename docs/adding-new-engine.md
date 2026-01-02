# Adding a New Game Engine

This guide walks through setting up a new game engine with browser-based VNC GUI and optional HTTP API.

## Architecture Overview

```
nginx:8080
├── /           → noVNC (browser VNC client)
├── /websockify → WebSocket-to-VNC bridge
├── /shell/     → ttyd (web terminal for debugging)
└── /api/*      → Flask/FastAPI (optional, for programmatic access)
```

**Stack:**
- **Xvfb** - Virtual framebuffer (headless display)
- **fluxbox** - Lightweight window manager
- **x11vnc** - VNC server for the virtual display
- **websockify** - WebSocket-to-VNC protocol bridge
- **noVNC** - Browser-based VNC client (cloned from GitHub)
- **ttyd** - Web terminal for debugging
- **nginx** - Reverse proxy, routes everything through port 8080
- **Wine** - (Optional) Runs Windows executables on Linux

## Prerequisites

- Docker (for local testing) or Google Cloud account
- The game/engine you want to containerize

**Cloud Run notes:**
- Native Linux apps work on Gen1 or Gen2
- Windows apps via Wine **require Gen2** (Gen1 doesn't support Wine's syscalls)

## Step-by-Step Setup

### 1. Create a new repository

```bash
# Follow the naming convention: <game>_server
mkdir mygame_server
cd mygame_server
git init
```

### 2. Copy template files

Copy these files from `classic_game_engines/templates/`:
- `Dockerfile`
- `start.sh`
- `nginx.conf`
- `fluxbox.menu`

### 3. Customize the Dockerfile

The template uses `python:3.11-slim` as the base image (Debian bookworm with Python pre-installed).

**For native Linux apps:**

```dockerfile
# Install your game from apt
RUN apt-get update \
    && apt-get install -y --no-install-recommends your-game \
    && rm -rf /var/lib/apt/lists/*
```

**For Windows apps (uncomment the Wine section first):**

```dockerfile
# Download and run installer silently
RUN curl -L "https://example.com/setup.exe" -o /tmp/setup.exe \
    && xvfb-run -a env WINEPREFIX="${WINEPREFIX}" wine64 /tmp/setup.exe /VERYSILENT \
    && rm /tmp/setup.exe
```

**Common Wine additions (if needed):**

```dockerfile
# Fonts
RUN xvfb-run -a env WINEPREFIX="${WINEPREFIX}" winetricks -q corefonts

# Visual C++ runtime
RUN xvfb-run -a env WINEPREFIX="${WINEPREFIX}" winetricks -q vcrun2015

# Rendering fixes
RUN xvfb-run -a env WINEPREFIX="${WINEPREFIX}" winetricks -q gdiplus
```

### 4. Customize start.sh

Update the game launch command:

```bash
# For native Linux apps:
GAME_CMD="your-game"

# For Windows apps via Wine:
GAME_CMD="wine64 ${WINEPREFIX}/drive_c/Game/game.exe"
```

Adjust screen resolution if needed:

```bash
Xvfb "$DISPLAY" -screen 0 1024x768x24 &
```

### 5. Customize fluxbox.menu

```
[begin] (MyGame)
  [exec] (Launch MyGame) {your-game}
  [separator]
  [exec] (Terminal) {xterm}
  [separator]
  [restart] (Restart)
  [exit] (Exit)
[end]
```

### 6. Build and test

**Local testing (if on amd64):**

```bash
docker build -t mygame-server .
docker run --rm -p 8080:8080 mygame-server
```

**Using Cloud Build (recommended):**

```bash
gcloud builds submit --tag gcr.io/YOUR_PROJECT/mygame-server --timeout=30m
```

Open http://localhost:8080 to see the VNC interface.

### 7. Deploy to Cloud Run

```bash
gcloud run deploy mygame-server \
    --image gcr.io/YOUR_PROJECT/mygame-server \
    --platform managed \
    --region us-central1 \
    --memory 2Gi \
    --cpu 2 \
    --port 8080 \
    --timeout 300 \
    --allow-unauthenticated
```

**For Wine apps, add:**

```bash
    --execution-environment gen2
```

## Adding an API (Optional)

If you want programmatic access to your engine:

1. Create a Flask/FastAPI server (e.g., `app/main.py`)
2. Add Python dependencies to `requirements.txt`
3. Add to Dockerfile:
   ```dockerfile
   COPY requirements.txt ./
   RUN pip install --no-cache-dir -r requirements.txt
   COPY app/ ./app/
   ```
4. Start the API in `start.sh`:
   ```bash
   gunicorn -b 127.0.0.1:8081 app.main:app &
   ```
5. Uncomment the `/api/` location block in `nginx.conf`

See `stockfish_server` for a full API example.

## Troubleshooting

### noVNC shows black screen

- Ensure Xvfb started before x11vnc
- Check the game actually launched (use `/shell/` to debug)
- Try different screen resolution

### Wine crashes or hangs

- Check if you need 32-bit libraries: `dpkg --add-architecture i386`
- Some games need specific Windows version: `winetricks win10`
- Enable Wine debug output temporarily: remove `WINEDEBUG=-all`

### Fonts look wrong / missing characters

- Install core fonts: `winetricks corefonts`
- For special symbols: `winetricks allfonts`

### Cloud Run issues

- Gen2 required for Wine apps
- Increase memory if OOM errors (2Gi minimum recommended)
- Use `--timeout=30m` for builds with VNC stack

## Checklist

- [ ] Game launches in container
- [ ] VNC accessible at http://localhost:8080
- [ ] Shell accessible at http://localhost:8080/shell/
- [ ] Game is playable through the browser
- [ ] Deployed to Cloud Run
- [ ] Added to engines table in `classic_game_engines/CLAUDE.md`

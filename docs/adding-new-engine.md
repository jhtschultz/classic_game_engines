# Adding a New Game Engine

This guide walks through setting up a new Windows game engine with HTTP API and browser-based VNC GUI.

## Architecture Overview

```
nginx:8080
├── /           → noVNC (browser VNC client)
├── /websockify → WebSocket-to-VNC bridge
└── /api/*      → FastAPI (optional, for programmatic access)
```

**Stack:**
- **Wine** - Runs Windows executables on Linux
- **Xvfb** - Virtual framebuffer (headless display)
- **x11vnc** - VNC server for the virtual display
- **websockify** - WebSocket-to-VNC protocol bridge
- **noVNC** - Browser-based VNC client
- **nginx** - Reverse proxy, routes everything through port 8080
- **fluxbox** - Lightweight window manager (optional but recommended)

## Prerequisites

- Docker
- The game/engine you want to containerize
- Cloud Run Gen2 (required for Wine support - Gen1 doesn't support the syscalls Wine needs)

## Step-by-Step Setup

### 1. Create a new repository

```bash
# Follow the naming convention: <game>_gui_server
mkdir mygame_gui_server
cd mygame_gui_server
git init
```

### 2. Copy template files

Copy these files from `classic_game_engines/templates/`:
- `Dockerfile`
- `start.sh`
- `nginx.conf`
- `fluxbox.menu`

### 3. Customize the Dockerfile

Key sections to modify:

```dockerfile
# Set your Wine prefix location
ENV WINEPREFIX=/opt/mygame/wineprefix

# Install your game - choose one approach:

# Option A: Download and run installer silently
RUN curl -L "https://example.com/setup.exe" -o /tmp/setup.exe \
    && xvfb-run -a env WINEPREFIX="${WINEPREFIX}" wine64 /tmp/setup.exe /VERYSILENT \
    && rm /tmp/setup.exe

# Option B: Copy pre-extracted game files
COPY game-files/ "${WINEPREFIX}/drive_c/MyGame/"
```

**Common Wine setup additions:**

```dockerfile
# If your game needs fonts
RUN xvfb-run -a env WINEPREFIX="${WINEPREFIX}" winetricks -q corefonts

# If your game needs Visual C++ runtime
RUN xvfb-run -a env WINEPREFIX="${WINEPREFIX}" winetricks -q vcrun2015

# If your game has rendering issues
RUN xvfb-run -a env WINEPREFIX="${WINEPREFIX}" winetricks -q gdiplus
```

### 4. Customize start.sh

Update the game executable path:

```bash
GAME_EXE="${WINEPREFIX}/drive_c/MyGame/mygame.exe"
```

Adjust screen resolution if needed:

```bash
# For games that need specific dimensions
Xvfb "$DISPLAY" -screen 0 1024x768x24 &
```

### 5. Customize fluxbox.menu

```
[begin] (MyGame)
  [exec] (Launch MyGame) {wine64 "C:\\MyGame\\mygame.exe"}
  [separator]
  [restart] (Restart)
  [exit] (Exit)
[end]
```

### 6. Build and test locally

```bash
docker build -t mygame-server .
docker run --rm -p 8080:8080 mygame-server
```

Open http://localhost:8080 in your browser to see the VNC interface.

### 7. Deploy to Cloud Run

```bash
# Build and push
gcloud builds submit --tag gcr.io/YOUR_PROJECT/mygame-server

# Deploy (must use Gen2 for Wine support)
gcloud run deploy mygame-server \
    --image gcr.io/YOUR_PROJECT/mygame-server \
    --platform managed \
    --execution-environment gen2 \
    --memory 2Gi \
    --cpu 2 \
    --port 8080
```

## Troubleshooting

### Wine crashes or hangs

- Check if you need 32-bit libraries: `dpkg --add-architecture i386`
- Some games need specific Windows version: `winetricks win10`
- Enable Wine debug output temporarily: remove `WINEDEBUG=-all`

### noVNC shows black screen

- Ensure Xvfb started before x11vnc
- Check the game actually launched: add logging to start.sh
- Try different screen resolution

### Fonts look wrong / missing characters

- Install core fonts: `winetricks corefonts`
- For special symbols: `winetricks allfonts`
- Check font linking in Wine registry

### Cloud Run specific issues

- Gen2 is required - Gen1 will fail with Wine
- Increase memory if OOM errors (2Gi minimum recommended)
- Increase startup timeout if Wine initialization is slow

## Adding an API (Optional)

If you want programmatic access to your engine:

1. Create a FastAPI server (`server.py`)
2. Add Python dependencies to Dockerfile
3. Start the API in `start.sh` on port 8081
4. Uncomment the `/api/` location block in `nginx.conf`

See `kingsrow_gui_server` for a full API example.

## Checklist

- [ ] Game launches in Docker locally
- [ ] VNC accessible at http://localhost:8080
- [ ] Game is playable through the browser
- [ ] Deployed to Cloud Run Gen2
- [ ] Added to engines table in `classic_game_engines/CLAUDE.md`

# CLAUDE.md

Meta/template repository for classic game engines exposed via HTTP API and browser-based VNC GUI.

**This is NOT a monorepo.** Each engine lives in its own independent repository with its own copies of all files. This repo provides:
- Starter templates to copy when creating new engine repos
- Documentation and best practices
- An index of existing engines

## Existing Engines

| Engine | Game | Repo | Status |
|--------|------|------|--------|
| `checkers_server` | Checkers | github.com/jhtschultz/checkers_server | Deployed |
| `gnubg_server` | Backgammon | github.com/jhtschultz/gnubg_server | Deployed |
| `stockfish_server` | Chess | github.com/jhtschultz/stockfish_server | Deployed |
| `wbridge5_server` | Bridge | github.com/jhtschultz/wbridge5_server | Deployed |

## Project Structure

```
classic_game_engines/
├── CLAUDE.md
├── docs/
│   └── adding-new-engine.md   # Step-by-step guide
├── templates/                  # Starter files to copy into new repos
│   ├── Dockerfile
│   ├── start.sh
│   ├── nginx.conf
│   └── fluxbox.menu
└── engines/                    # Local clones (git-ignored, each has own .git)
    ├── checkers/               # → github.com/jhtschultz/checkers_server
    ├── gnubg/                  # → github.com/jhtschultz/gnubg_server
    ├── stockfish/              # → github.com/jhtschultz/stockfish_server
    └── wbridge5/               # → github.com/jhtschultz/wbridge5_server
```

## How to Use

1. Read `docs/adding-new-engine.md`
2. Create a new repo: `<game>_server`
3. Copy files from `templates/` into your new repo
4. Customize for your specific game engine
5. Add your engine to the table above

## TODO

- [x] Initialize git repo
- [x] Extract common patterns into `templates/`
- [x] Write `docs/adding-new-engine.md`
- [x] Rename kingsrow_gui_server → checkers_server on GitHub
- [x] Rename gnubg_gui_server → gnubg_server on GitHub
- [x] Move repos to engines/ and update remotes
- [x] Extract wbridge5 from gnubg into wbridge5_server

## Common Architecture

All engines follow this pattern:

```
nginx:8080
├── /           → noVNC (browser VNC client)
├── /websockify → WebSocket→VNC bridge
├── /shell/     → ttyd (web terminal for debugging)
└── /api/*      → Flask/FastAPI (optional)
```

## Key Learnings

- **Use `python:3.11-slim`** as base image - it's Debian bookworm with Python pre-installed, no downside
- **Clone noVNC from GitHub** - Debian apt packages have websocket compatibility issues that break keyboard input
- **Cloud Run Gen2** only required for Wine apps - native Linux apps work fine on Gen1
- **Add ttyd** for `/shell/` access - invaluable for debugging container issues
- **Build timeout**: Use `--timeout=30m` for images with VNC stack (they're large)
- **Memory**: 2Gi minimum recommended for VNC stack

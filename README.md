# bootstrap

Sets up a fresh Windows machine with my usual apps. Anything already installed is skipped, so it's safe to re-run.

## Usage

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/pradishb/bootstrap/master/bootstrap.ps1 | iex
```

Or from a local clone:

```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

The script asks for administrator rights (UAC) and continues in a new elevated window.

## What it installs

Via winget:

- Brave
- Cloudflare One Client (WARP)
- Discord
- Google Drive
- KeePass
- VS Code
- uv
- qBittorrent
- AnyDesk
- VLC
- Git
- Clink
- GitHub CLI
- Claude Code
- Node.js LTS
- AutoHotkey
- ShareX
- Task (Taskfile)

Other sources:

- **Wrangler** — `npm install -g wrangler`
- **RustDesk** — latest x64 MSI from GitHub releases

Settings:

- **Claude Code chime** — copies `sounds/done.wav` to `~/.claude/sounds/` and adds a `Stop` hook to `~/.claude/settings.json` that plays it whenever Claude finishes a response (your other settings are kept)

If winget is missing (common on a brand-new install), the script tries to register App Installer first. If that fails, update **App Installer** from the Microsoft Store and run it again.

A summary of installed, skipped, and failed apps is printed at the end.

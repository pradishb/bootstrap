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
- [KeePassPasskey](https://keepasspasskey.github.io/) (Microsoft Store) — needs Windows 11 24H2+. After install, open it once, click **Install plugin**, restart KeePass, then enable it under Windows' advanced passkey options
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
- Tailscale
- Syncthing
- 7-Zip

Other sources:

- **Wrangler** — `npm install -g wrangler`
- **RustDesk** — latest x64 MSI from GitHub releases

Scripts:

- **Salt wrappers** — copies `bin/*.cmd` (`salt`, `salt-call`, `salt-key`, `salt-run`) to `~/.local/bin` and adds that folder to the user PATH. They run the salt CLI on the remote salt-master over ssh.

Settings:

- **Syncthing at login** — adds a `Syncthing` shortcut to your Startup folder that runs it in the background (`--no-console --no-browser`), and starts it right away. After a winget upgrade of Syncthing, re-run the script to repoint the shortcut. The web UI is at http://127.0.0.1:8384
- **Claude Code chime** — copies `sounds/done.wav` to `~/.claude/sounds/` and adds a `Stop` hook to `~/.claude/settings.json` that plays it whenever Claude finishes a response (your other settings are kept)

If winget is missing (common on a brand-new install), the script tries to register App Installer first. If that fails, update **App Installer** from the Microsoft Store and run it again.

A summary of installed, skipped, and failed apps is printed at the end.

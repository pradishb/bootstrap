# Installs my usual apps on a fresh Windows machine. Skips anything already installed.
# Run directly from GitHub:
#   irm https://raw.githubusercontent.com/pradishb/bootstrap/master/bootstrap.ps1 | iex
# or locally:
#   powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
# Uses `return` rather than `exit` so an `irm | iex` run doesn't close the caller's shell.

$scriptUrl = 'https://raw.githubusercontent.com/pradishb/bootstrap/master/bootstrap.ps1'

# --- Relaunch elevated (UAC prompt) if not already admin ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Requesting administrator rights...' -ForegroundColor Yellow
    # $PSCommandPath is empty when run via `irm | iex`, so re-download in the elevated shell instead
    if ($PSCommandPath) { $launch = "-File `"$PSCommandPath`"" }
    else { $launch = "-Command `"irm $scriptUrl | iex`"" }
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass $launch" -ErrorAction Stop
    } catch {
        Write-Host 'Administrator rights were declined. Exiting.' -ForegroundColor Red
    }
    return
}

$ErrorActionPreference = 'Continue'

$apps = [ordered]@{
    'Brave'                 = 'Brave.Brave'
    'Cloudflare One Client' = 'Cloudflare.Warp'
    'Discord'               = 'Discord.Discord'
    'Google Drive'          = 'Google.GoogleDrive'
    'KeePass'               = 'DominikReichl.KeePass'
    'VS Code'               = 'Microsoft.VisualStudioCode'
    'uv'                    = 'astral-sh.uv'
    'qBittorrent'           = 'qBittorrent.qBittorrent'
    'AnyDesk'               = 'AnyDesk.AnyDesk'
    'VLC'                   = 'VideoLAN.VLC'
    'Git'                   = 'Git.Git'
    'Clink'                 = 'chrisant996.Clink'
    'GitHub CLI'            = 'GitHub.cli'
    'Claude Code'           = 'Anthropic.ClaudeCode'
    'Node.js LTS'           = 'OpenJS.NodeJS.LTS'   # needed for wrangler
    'AutoHotkey'            = 'AutoHotkey.AutoHotkey'
    'ShareX'                = 'ShareX.ShareX'
    'Task'                  = 'Task.Task'           # taskfile.dev
}

$installed = @(); $skipped = @(); $failed = @()

# --- Make sure winget is available (on a brand-new install it may not be registered yet) ---
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'winget not found, registering App Installer...' -ForegroundColor Yellow
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
    } catch {}
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host 'winget is still unavailable. Update "App Installer" from the Microsoft Store and re-run.' -ForegroundColor Red
        return
    }
}

winget source update | Out-Null

# --- winget apps ---
foreach ($name in $apps.Keys) {
    $id = $apps[$name]
    winget list --id $id -e --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[skip]    $name already installed" -ForegroundColor DarkGray
        $skipped += $name
        continue
    }

    Write-Host "[install] $name ($id)..." -ForegroundColor Cyan
    winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { $installed += $name } else { $failed += "$name (exit $LASTEXITCODE)" }
}

# Pick up PATH changes from the installs above (e.g. node/npm) without reopening the shell
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

# --- Wrangler (Cloudflare CLI; npm package, not in winget) ---
if (Get-Command wrangler -ErrorAction SilentlyContinue) {
    Write-Host '[skip]    Wrangler already installed' -ForegroundColor DarkGray
    $skipped += 'Wrangler'
} elseif (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    $failed += 'Wrangler (npm not found - Node.js install failed?)'
} else {
    Write-Host '[install] Wrangler (npm)...' -ForegroundColor Cyan
    npm install -g wrangler
    if ($LASTEXITCODE -eq 0) { $installed += 'Wrangler' } else { $failed += "Wrangler (npm exit $LASTEXITCODE)" }
}

# --- RustDesk (not in winget; install latest MSI from GitHub) ---
$rustdeskPresent = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                                    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
                   Where-Object { $_.DisplayName -like 'RustDesk*' }
if ($rustdeskPresent -or (Test-Path "$env:ProgramFiles\RustDesk\rustdesk.exe")) {
    Write-Host '[skip]    RustDesk already installed' -ForegroundColor DarkGray
    $skipped += 'RustDesk'
} else {
    Write-Host '[install] RustDesk (GitHub release)...' -ForegroundColor Cyan
    try {
        $release = Invoke-RestMethod 'https://api.github.com/repos/rustdesk/rustdesk/releases/latest'
        $asset = $release.assets | Where-Object { $_.name -match '^rustdesk-.*-x86_64\.msi$' } | Select-Object -First 1
        $msi = Join-Path $env:TEMP $asset.name
        Invoke-WebRequest $asset.browser_download_url -OutFile $msi -UseBasicParsing
        $p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart" -Wait -PassThru
        if ($p.ExitCode -in 0, 3010) { $installed += 'RustDesk' } else { $failed += "RustDesk (msiexec $($p.ExitCode))" }
        Remove-Item $msi -ErrorAction SilentlyContinue
    } catch {
        $failed += "RustDesk ($($_.Exception.Message))"
    }
}

# --- Claude Code: chime when Claude finishes a response (Stop hook) ---
# A loud-but-soft two-note chime, for weak speakers. The .wav lives in this repo;
# the hook is merged into ~/.claude/settings.json, keeping everything else there.
$claudeDir = Join-Path $env:USERPROFILE '.claude'
$wav = Join-Path $claudeDir 'sounds\done.wav'
$settingsPath = Join-Path $claudeDir 'settings.json'
try {
    if (-not (Test-Path $wav)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $wav) | Out-Null
        Invoke-WebRequest 'https://raw.githubusercontent.com/pradishb/bootstrap/master/sounds/done.wav' -OutFile $wav -UseBasicParsing
    }
    $settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json } else { $null }
    if (-not $settings) { $settings = [pscustomobject]@{} }
    if ((Get-Content $settingsPath -Raw -ErrorAction SilentlyContinue) -match 'done\.wav') {
        Write-Host '[skip]    Claude Code chime already set up' -ForegroundColor DarkGray
        $skipped += 'Claude Code chime'
    } else {
        Write-Host '[install] Claude Code chime (Stop hook)...' -ForegroundColor Cyan
        $hook = [pscustomobject]@{
            hooks = @([pscustomobject]@{
                type    = 'command'
                command = 'powershell.exe'
                args    = @('-NoProfile', '-Command', "(New-Object Media.SoundPlayer '$wav').PlaySync()")
                async   = $true
            })
        }
        if (-not $settings.hooks) { $settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) }
        $stop = @($settings.hooks.Stop | Where-Object { $_ }) + $hook
        $settings.hooks | Add-Member -NotePropertyName Stop -NotePropertyValue $stop -Force
        New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
        # No BOM: Windows PowerShell's UTF8 encoding writes one, and a JSON parser may reject it.
        [IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20))
        $installed += 'Claude Code chime'
    }
} catch {
    $failed += "Claude Code chime ($($_.Exception.Message))"
}

# --- Summary ---
Write-Host "`n===== Summary =====" -ForegroundColor White
Write-Host "Installed: $($installed -join ', ')" -ForegroundColor Green
Write-Host "Skipped:   $($skipped -join ', ')" -ForegroundColor DarkGray
if ($failed) { Write-Host "Failed:    $($failed -join ', ')" -ForegroundColor Red }

Read-Host "`nPress Enter to close"

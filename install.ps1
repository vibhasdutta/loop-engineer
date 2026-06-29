# Loop Engineer — Windows installer
# Usage:
#   .\install.ps1              -> Claude Code (default)
#   .\install.ps1 -Cursor      -> Cursor
#   .\install.ps1 -Gemini      -> Gemini CLI
#   .\install.ps1 -Antigravity -> Antigravity (agy)
#   .\install.ps1 -Codex       -> OpenAI Codex CLI
#   .\install.ps1 -OpenCode    -> OpenCode
#   .\install.ps1 -Hermes      -> Hermes Agent
#   .\install.ps1 -All         -> all platforms
# Also accepts bash-style flags: --cursor, --gemini, --codex, --opencode, --hermes, --all

param(
    [switch]$Cursor,
    [switch]$Gemini,
    [switch]$Antigravity,
    [switch]$Codex,
    [switch]$OpenCode,
    [switch]$Hermes,
    [switch]$All,
    [Parameter(ValueFromRemainingArguments)][string[]]$ExtraArgs
)

# Accept bash-style --flags passed as positional args
foreach ($arg in $ExtraArgs) {
    switch ($arg.ToLower().TrimStart('-')) {
        'cursor'      { $Cursor = $true }
        'gemini'      { $Gemini = $true }
        'antigravity' { $Antigravity = $true }
        'codex'       { $Codex = $true }
        'opencode'    { $OpenCode = $true }
        'hermes'      { $Hermes = $true }
        'all'         { $All = $true }
    }
}

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Install-Claude {
    $dir = "$env:USERPROFILE\.claude\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\claude\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\claude\agents\*.md" "$dir\agents\" -Force
    Write-Host "Claude Code: installed to $dir"
    Write-Host "Restart Claude Code, then use /loop-engineer in any project."
}

function Install-Cursor {
    $dir = "$env:USERPROFILE\.cursor\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\cursor\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\cursor\agents\*.md" "$dir\agents\" -Force
    Write-Host "Cursor: installed to $dir"
    Write-Host "Restart Cursor, then use /loop-engineer in any project."
}

function Install-Gemini {
    $dir = "$env:USERPROFILE\.gemini\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\gemini\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\gemini\GEMINI.md" "$dir\GEMINI.md" -Force
    Copy-Item "$RepoDir\platforms\gemini\gemini-extension.json" "$dir\gemini-extension.json" -Force
    Copy-Item "$RepoDir\platforms\gemini\agents\*.md" "$dir\agents\" -Force
    $cmdSrc = "$RepoDir\platforms\gemini\commands"
    if (Test-Path $cmdSrc) {
        New-Item -ItemType Directory -Force "$env:USERPROFILE\.gemini\commands" | Out-Null
        Copy-Item "$cmdSrc\*.toml" "$env:USERPROFILE\.gemini\commands\" -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Gemini CLI: installed to $dir"
    Write-Host "Restart Gemini CLI or run '/skills reload' inside a session to activate."
}

function Install-Antigravity {
    # Install for Antigravity CLI (agy)
    $cliDir = "$env:USERPROFILE\.gemini\antigravity-cli\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$cliDir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\antigravity\SKILL.md" "$cliDir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\antigravity\AGENTS.md" "$cliDir\AGENTS.md" -Force
    Copy-Item "$RepoDir\platforms\antigravity\agents\*.md" "$cliDir\agents\" -Force
    Write-Host "Antigravity CLI: installed to $cliDir"

    # Install for Antigravity 2.0 desktop
    $appDir = "$env:USERPROFILE\.agents\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$appDir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\antigravity\SKILL.md" "$appDir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\antigravity\AGENTS.md" "$appDir\AGENTS.md" -Force
    Copy-Item "$RepoDir\platforms\antigravity\agents\*.md" "$appDir\agents\" -Force
    Write-Host "Antigravity 2.0: installed to $appDir"

    Write-Host "Copy platforms\antigravity\AGENTS.md to your project root for workspace context."
    Write-Host "For CLI migration from Gemini CLI, run: agy plugin import gemini"
}

function Install-OpenCode {
    $dir = "$env:LOCALAPPDATA\opencode\skills\loop-engineer"
    # OpenCode on Windows uses %LOCALAPPDATA%/opencode or ~/.config/opencode
    $configDir = "$env:USERPROFILE\.config\opencode\skills\loop-engineer"
    # Try both locations; prefer ~/.config/opencode (cross-platform convention)
    $dir = $configDir
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\opencode\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\opencode\AGENTS.md" "$dir\AGENTS.md" -Force
    Copy-Item "$RepoDir\platforms\opencode\agents\*.md" "$dir\agents\" -Force
    $cmdSrc = "$RepoDir\platforms\opencode\commands"
    if (Test-Path $cmdSrc) {
        New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\opencode\commands" | Out-Null
        Copy-Item "$cmdSrc\*.md" "$env:USERPROFILE\.config\opencode\commands\" -Force -ErrorAction SilentlyContinue
    }
    Write-Host "OpenCode: installed to $dir"
    Write-Host "Restart OpenCode or use /loop-engineer in any session."
}

function Install-Codex {
    $dir = "$env:USERPROFILE\.codex\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\codex\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\codex\agents\*.toml" "$dir\agents\" -Force
    Write-Host "Codex CLI: installed to $dir"
    Write-Host "Use /loop-engineer in any Codex session."
}

function Install-Hermes {
    $dir = "$env:USERPROFILE\.hermes\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\hermes\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\hermes\HERMES.md" "$dir\HERMES.md" -Force
    Copy-Item "$RepoDir\platforms\hermes\agents\*.md" "$dir\agents\" -Force
    Write-Host "Hermes Agent: installed to $dir"
    Write-Host "Copy platforms\hermes\HERMES.md to your project root for workspace context."
    Write-Host "Use /loop-engineer in any Hermes session."
}

if ($All) {
    Install-Claude
    Install-Cursor
    Install-Gemini
    Install-Codex
    Install-OpenCode
    Install-Hermes
} elseif ($Cursor) {
    Install-Cursor
} elseif ($Gemini) {
    Install-Gemini
} elseif ($Antigravity) {
    Install-Antigravity
} elseif ($Codex) {
    Install-Codex
} elseif ($OpenCode) {
    Install-OpenCode
} elseif ($Hermes) {
    Install-Hermes
} else {
    Install-Claude
}

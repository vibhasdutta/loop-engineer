# Loop Engineer - Windows installer
# Usage:
#   .\install.ps1              -> Claude Code (default)
#   .\install.ps1 -Cursor      -> Cursor
#   .\install.ps1 -Gemini      -> Gemini CLI
#   .\install.ps1 -Antigravity -> Antigravity (agy)
#   .\install.ps1 -Codex       -> OpenAI Codex CLI
#   .\install.ps1 -OpenCode    -> OpenCode
#   .\install.ps1 -Hermes      -> Hermes Agent
#   .\install.ps1 -All         -> all platforms
#   .\install.ps1 -Update      -> git pull + re-install Claude Code
#   .\install.ps1 -Update -Cursor -> git pull + re-install Cursor
# Also accepts bash-style flags: --cursor, --gemini, --codex, --opencode, --hermes, --all, --update

param(
    [switch]$Cursor,
    [switch]$Gemini,
    [switch]$Antigravity,
    [switch]$Codex,
    [switch]$OpenCode,
    [switch]$Hermes,
    [switch]$All,
    [switch]$Update,
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
        'update'      { $Update = $true }
    }
}

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($Update) {
    $gitDir = Join-Path $RepoDir ".git"
    if (Test-Path $gitDir) {
        Write-Host "Pulling latest changes..."
        git -C $RepoDir pull
    }
}

function Copy-Scripts($dir) {
    New-Item -ItemType Directory -Force "$dir\scripts" | Out-Null
    try { Copy-Item "$RepoDir\scripts\init-loop.sh"  "$dir\scripts\" -Force -ErrorAction SilentlyContinue } catch {}
    try { Copy-Item "$RepoDir\scripts\init-loop.ps1" "$dir\scripts\" -Force -ErrorAction SilentlyContinue } catch {}
}

function Copy-KnowledgeSources($platformAgentsDir, $destAgentsDir) {
    $ks = "$platformAgentsDir\knowledge-sources"
    if (Test-Path $ks) {
        New-Item -ItemType Directory -Force "$destAgentsDir\knowledge-sources" | Out-Null
        Copy-Item "$ks\*.md" "$destAgentsDir\knowledge-sources\" -Force -ErrorAction SilentlyContinue
    }
}

function Install-Claude {
    $dir = "$env:USERPROFILE\.claude\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\claude\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\claude\agents\*.md" "$dir\agents\" -Force
    Copy-KnowledgeSources "$RepoDir\platforms\claude\agents" "$dir\agents"
    Copy-Scripts $dir
    Write-Host "Claude Code: installed to $dir"
    Write-Host "Restart Claude Code, then use /loop-engineer in any project."
}

function Install-Cursor {
    $dir = "$env:USERPROFILE\.cursor\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\cursor\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\cursor\agents\*.md" "$dir\agents\" -Force
    Copy-KnowledgeSources "$RepoDir\platforms\cursor\agents" "$dir\agents"
    Copy-Scripts $dir
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
    Copy-KnowledgeSources "$RepoDir\platforms\gemini\agents" "$dir\agents"
    Copy-Scripts $dir
    $cmdSrc = "$RepoDir\platforms\gemini\commands"
    if (Test-Path $cmdSrc) {
        New-Item -ItemType Directory -Force "$env:USERPROFILE\.gemini\commands" | Out-Null
        Copy-Item "$cmdSrc\*.toml" "$env:USERPROFILE\.gemini\commands\" -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Gemini CLI: installed to $dir"
    Write-Host "Restart Gemini CLI or run '/skills reload' inside a session to activate."
}

function Install-AntigravitySurface($dest) {
    New-Item -ItemType Directory -Force "$dest\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\antigravity\SKILL.md" "$dest\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\antigravity\AGENTS.md" "$dest\AGENTS.md" -Force
    Copy-Item "$RepoDir\platforms\antigravity\agents\*.md" "$dest\agents\" -Force
    Copy-KnowledgeSources "$RepoDir\platforms\antigravity\agents" "$dest\agents"
    Copy-Scripts $dest
}

function Install-Antigravity {
    $cliDir = "$env:USERPROFILE\.gemini\antigravity-cli\skills\loop-engineer"
    Install-AntigravitySurface $cliDir
    Write-Host "Antigravity CLI (agy): installed to $cliDir"

    $ideDir = "$env:USERPROFILE\.gemini\antigravity\skills\loop-engineer"
    Install-AntigravitySurface $ideDir
    Write-Host "Antigravity IDE: installed to $ideDir"

    $appDir = "$env:USERPROFILE\.gemini\config\skills\loop-engineer"
    Install-AntigravitySurface $appDir
    Write-Host "Antigravity 2.0 desktop: installed to $appDir"

    Write-Host "Copy platforms\antigravity\AGENTS.md to your project root for workspace context."
}

function Install-OpenCode {
    $dir = "$env:USERPROFILE\.config\opencode\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\opencode\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\opencode\AGENTS.md" "$dir\AGENTS.md" -Force
    Copy-Item "$RepoDir\platforms\opencode\agents\*.md" "$dir\agents\" -Force
    Copy-KnowledgeSources "$RepoDir\platforms\opencode\agents" "$dir\agents"
    Copy-Scripts $dir
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
    New-Item -ItemType Directory -Force "$dir\knowledge-sources" | Out-Null
    Copy-Item "$RepoDir\platforms\codex\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\codex\agents\*.toml" "$dir\agents\" -Force
    Copy-Item "$RepoDir\platforms\codex\knowledge-sources\*.md" "$dir\knowledge-sources\" -Force -ErrorAction SilentlyContinue
    Copy-Item "$RepoDir\platforms\codex\knowledge-sources.md" "$dir\knowledge-sources.md" -Force -ErrorAction SilentlyContinue
    Copy-Scripts $dir
    Write-Host "Codex CLI: installed to $dir"
    Write-Host "Use /loop-engineer in any Codex session."
}

function Install-Hermes {
    $dir = "$env:USERPROFILE\.hermes\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\hermes\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\hermes\HERMES.md" "$dir\HERMES.md" -Force
    Copy-Item "$RepoDir\platforms\hermes\agents\*.md" "$dir\agents\" -Force
    Copy-KnowledgeSources "$RepoDir\platforms\hermes\agents" "$dir\agents"
    Copy-Scripts $dir
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

if ($Update) {
    Write-Host "loop-engineer updated to latest"
}

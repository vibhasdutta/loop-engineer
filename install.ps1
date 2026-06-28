# Loop Engineer — Windows installer
# Usage:
#   .\install.ps1              -> Claude Code (default)
#   .\install.ps1 -Cursor      -> Cursor
#   .\install.ps1 -Gemini      -> Gemini CLI
#   .\install.ps1 -Antigravity -> Antigravity (agy)
#   .\install.ps1 -Codex       -> OpenAI Codex CLI
#   .\install.ps1 -All         -> all platforms
# Also accepts bash-style flags: --cursor, --gemini, --codex, --all

param(
    [switch]$Cursor,
    [switch]$Gemini,
    [switch]$Antigravity,
    [switch]$Codex,
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
    Write-Host "Gemini CLI: installed to $dir"
    Write-Host "Run: gemini extension install $dir"
}

function Install-Antigravity {
    $dir = "$env:USERPROFILE\.gemini\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\antigravity\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\antigravity\agents\*.md" "$dir\agents\" -Force
    Write-Host "Antigravity: installed to $dir"
    Write-Host "Add AGENTS.md from platforms\antigravity\AGENTS.md to your project root."
}

function Install-Codex {
    $dir = "$env:USERPROFILE\.codex\skills\loop-engineer"
    New-Item -ItemType Directory -Force "$dir\agents" | Out-Null
    Copy-Item "$RepoDir\platforms\codex\SKILL.md" "$dir\SKILL.md" -Force
    Copy-Item "$RepoDir\platforms\codex\agents\*.toml" "$dir\agents\" -Force
    Write-Host "Codex CLI: installed to $dir"
    Write-Host "Use /loop-engineer in any Codex session."
}

if ($All) {
    Install-Claude
    Install-Cursor
    Install-Gemini
    Install-Codex
} elseif ($Cursor) {
    Install-Cursor
} elseif ($Gemini) {
    Install-Gemini
} elseif ($Antigravity) {
    Install-Antigravity
} elseif ($Codex) {
    Install-Codex
} else {
    Install-Claude
}

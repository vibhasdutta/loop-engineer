# Loop Engineer — Windows installer
# Usage:
#   .\install.ps1           -> Claude Code
#   .\install.ps1 -Codex    -> Codex CLI
#   .\install.ps1 -Both     -> both

param(
    [switch]$Codex,
    [switch]$Both
)

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Install-Claude {
    $dir = "$env:USERPROFILE\.claude\skills\loop-engineer"
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item "$RepoDir\skills\loop-engineer\SKILL.md" "$dir\SKILL.md"
    Write-Host "Claude Code: installed to $dir"
    Write-Host "Restart Claude Code, then use /loop-engineer in any project."
}

function Install-Codex {
    $dir = "$env:USERPROFILE\.codex\skills\loop-engineer-codex"
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item "$RepoDir\skills\loop-engineer-codex\SKILL.md" "$dir\SKILL.md"
    Write-Host "Codex CLI: installed to $dir"
    Write-Host "Use /loop-engineer-codex in any Codex session."
}

if ($Both) {
    Install-Claude
    Install-Codex
} elseif ($Codex) {
    Install-Codex
} else {
    Install-Claude
}

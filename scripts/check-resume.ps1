# check-resume.ps1 - deterministic scan of loop-stack/ for active/done/extended-done loops.
# Run this before any judgment call about resuming - do not re-derive its output by hand.
# Usage: & .\check-resume.ps1
#
# Output (one line per loop found; do not reformat when relaying to the user):
#   ACTIVE <loop-id> | State: <state> | Task: <task> | Progress: <progress>
#   DONE <loop-id>
#   EXTENDED_DONE <loop-id>
#   NONE   (only printed if nothing at all was found)

$script:foundAny = $false

if (Test-Path "loop-stack") {
  Get-ChildItem -Path "loop-stack" -Directory | ForEach-Object {
    $id = $_.Name
    if ($id -eq ".global") { return }

    if ($id -like "*_EXTENDED_DONE") {
      $base = $id -replace "_EXTENDED_DONE$", ""
      Write-Host "EXTENDED_DONE $base"
      $script:foundAny = $true
      return
    }
    if ($id -like "*_DONE") {
      $base = $id -replace "_DONE$", ""
      Write-Host "DONE $base"
      $script:foundAny = $true
      return
    }

    $statusFile = Join-Path $_.FullName "STATUS.md"
    if (Test-Path $statusFile) {
      $lines = Get-Content $statusFile
      $state = ""
      $task = ""
      $progress = ""
      for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "## State" -and ($i + 1) -lt $lines.Count) { $state = $lines[$i + 1] }
        if ($lines[$i] -eq "## Current Task" -and ($i + 1) -lt $lines.Count) { $task = $lines[$i + 1] }
        if ($lines[$i] -eq "## Task Progress" -and ($i + 1) -lt $lines.Count) { $progress = $lines[$i + 1] }
      }
      Write-Host "ACTIVE $id | State: $state | Task: $task | Progress: $progress"
      $script:foundAny = $true
    }
  }
}

if (-not $script:foundAny) {
  Write-Host "NONE"
}

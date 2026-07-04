#!/usr/bin/env bash
# check-resume.sh — deterministic scan of loop-stack/ for active/done/extended-done loops.
# Run this before any judgment call about resuming — do not re-derive its output by hand.
# Usage: bash check-resume.sh
#
# Output (one line per loop found; do not reformat when relaying to the user):
#   ACTIVE <loop-id> | State: <state> | Task: <task> | Progress: <progress>
#   DONE <loop-id>
#   EXTENDED_DONE <loop-id>
#   NONE   (only printed if nothing at all was found)

set -u

found_any=false

if [[ -d loop-stack ]]; then
  for dir in loop-stack/*/; do
    [[ -d "$dir" ]] || continue
    id="$(basename "$dir")"
    [[ "$id" == ".global" ]] && continue

    if [[ "$id" == *_EXTENDED_DONE ]]; then
      base="${id%_EXTENDED_DONE}"
      echo "EXTENDED_DONE $base"
      found_any=true
      continue
    fi
    if [[ "$id" == *_DONE ]]; then
      base="${id%_DONE}"
      echo "DONE $base"
      found_any=true
      continue
    fi

    status="${dir}STATUS.md"
    if [[ -f "$status" ]]; then
      state="$(grep -A1 '^## State' "$status" | tail -1)"
      task="$(grep -A1 '^## Current Task' "$status" | tail -1)"
      progress="$(grep -A1 '^## Task Progress' "$status" | tail -1)"
      echo "ACTIVE $id | State: $state | Task: $task | Progress: $progress"
      found_any=true
    fi
  done
fi

if ! $found_any; then
  echo "NONE"
fi

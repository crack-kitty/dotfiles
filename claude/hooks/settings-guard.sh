#!/usr/bin/env bash
# settings-guard: restore claude/settings.json when the harness (or any tool)
# silently drifts it from the committed version. Wired as a Stop hook so it runs
# at the end of every session, hands-off, on every machine the dotfiles sync to.
#
# On drift it (1) copies the drifted file to backups/ so nothing is lost,
# (2) restores the committed version, (3) logs one line. Both backups/ and the
# log live under gitignored paths, so the guard never creates new drift itself.
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"   # symlink into the dotfiles repo
FILE="settings.json"           # path relative to CLAUDE_DIR (a repo subdir)
LOG="${CLAUDE_DIR}/logs/settings-guard.log"
BACKUP_DIR="${CLAUDE_DIR}/backups"

# Only act inside a git work tree; stay silent otherwise.
git -C "$CLAUDE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Nothing to do when the live file already matches HEAD.
if git -C "$CLAUDE_DIR" diff --quiet -- "$FILE" 2>/dev/null; then
  exit 0
fi

ts="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG")"
cp "${CLAUDE_DIR}/${FILE}" "${BACKUP_DIR}/settings.json.${ts}.drift"
git -C "$CLAUDE_DIR" checkout -- "$FILE"
printf '%s reverted %s to HEAD; drift saved to backups/settings.json.%s.drift\n' \
  "$ts" "$FILE" "$ts" >> "$LOG"
exit 0

#!/usr/bin/env bash
set -u

source_name="${1:-}"
log_path="${2:-/dev/null}"
repo="${DASHBOARD_HOOK_REPO:-$HOME/appdev/dashboard}"
uv_bin="${DASHBOARD_HOOK_UV:-$HOME/.local/bin/uv}"
hook_cwd="${DASHBOARD_HOOK_CWD:-$PWD}"

case "$source_name" in
  codex|claude-code) ;;
  *)
    mkdir -p "$(dirname "$log_path")" 2>/dev/null || true
    printf '{"ok":false,"result":"invalid_source","source":"%s"}\n' "$source_name" >> "$log_path" 2>/dev/null || true
    exit 2
    ;;
esac

mkdir -p "$(dirname "$log_path")" 2>/dev/null || true

skip() {
  reason="$1"
  printf '{"ok":true,"result":"skipped_dashboard_unavailable","reason":"%s","saved_to":[],"openbrain_saved":false}\n' "$reason" >> "$log_path" 2>/dev/null || true
  exit 0
}

[[ -d "$repo" ]] || skip "missing_repo"
[[ -x "$uv_bin" ]] || skip "missing_uv"
cd "$repo" || skip "cd_failed"

DASHBOARD_HOOK_CWD="$hook_cwd" "$uv_bin" run python -m dashboard.report --source "$source_name" >> "$log_path" 2>&1 || {
  status=$?
  printf '{"ok":false,"result":"wrapper_command_failed","status":%s,"saved_to":[],"openbrain_saved":false}\n' "$status" >> "$log_path" 2>/dev/null || true
}

exit 0

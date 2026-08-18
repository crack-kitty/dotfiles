#!/usr/bin/env bash
set -u

source_name="${1:-}"
log_path="${2:-/dev/null}"
repo="${DASHBOARD_HOOK_REPO:-$HOME/appdev/dashboard}"
uv_bin="${DASHBOARD_HOOK_UV:-$HOME/.local/bin/uv}"
hook_cwd="${DASHBOARD_HOOK_CWD:-$PWD}"
hook_timeout="${DASHBOARD_HOOK_TIMEOUT_SECONDS:-7}"

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
[[ "$hook_timeout" =~ ^[0-9]+([.][0-9]+)?$ ]] || skip "invalid_timeout"
timeout_bin="$(command -v timeout 2>/dev/null || true)"
[[ -n "$timeout_bin" ]] || skip "missing_timeout"
cd "$repo" || skip "cd_failed"

{
  DASHBOARD_HOOK_CWD="$hook_cwd" "$timeout_bin" \
    --signal=TERM \
    --kill-after=1s \
    "${hook_timeout}s" \
    "$uv_bin" run python -m dashboard.report --source "$source_name" >> "$log_path" 2>&1
  status=$?
} 2>> "$log_path"

case "$status" in
  0) ;;
  124|137)
    printf '{"ok":true,"result":"skipped_dashboard_timeout","timeout_seconds":"%s","saved_to":[],"openbrain_saved":false}\n' "$hook_timeout" >> "$log_path" 2>/dev/null || true
    ;;
  *)
    printf '{"ok":false,"result":"wrapper_command_failed","status":%s,"saved_to":[],"openbrain_saved":false}\n' "$status" >> "$log_path" 2>/dev/null || true
    ;;
esac

exit 0

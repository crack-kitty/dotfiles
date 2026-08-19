#!/usr/bin/env bash
set -u

source_name="${1:-}"
log_path="${2:-/dev/null}"
repo="${DASHBOARD_HOOK_REPO:-$HOME/appdev/dashboard}"
uv_bin="${DASHBOARD_HOOK_UV:-$HOME/.local/bin/uv}"
hook_cwd="${DASHBOARD_HOOK_CWD:-$PWD}"
hook_timeout="${DASHBOARD_HOOK_TIMEOUT_SECONDS:-7}"
session_debounce="${DASHBOARD_SESSION_DEBOUNCE_SECONDS:-180}"
host_openbrain_dsn="${DASHBOARD_HOOK_OPENBRAIN_DATABASE_URL:-}"

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
[[ "$session_debounce" =~ ^[0-9]+([.][0-9]+)?$ ]] || skip "invalid_debounce"
timeout_bin="$(command -v timeout 2>/dev/null || true)"
[[ -n "$timeout_bin" ]] || skip "missing_timeout"
cd "$repo" || skip "cd_failed"

{
  DASHBOARD_HOOK_CWD="$hook_cwd" OPENBRAIN_DATABASE_URL="$host_openbrain_dsn" "$timeout_bin" \
    --signal=TERM \
    --kill-after=1s \
    "${hook_timeout}s" \
    "$uv_bin" run python -m dashboard.report --source "$source_name" >> "$log_path" 2>&1
  status=$?
} 2>> "$log_path"

case "$status" in
  0)
    reconcile_log="${log_path}.reconcile"
    setsid_bin="$(command -v setsid 2>/dev/null || true)"
    if [[ -n "$setsid_bin" ]]; then
      OPENBRAIN_DATABASE_URL="$host_openbrain_dsn" \
        DASHBOARD_SESSION_DEBOUNCE_SECONDS="$session_debounce" \
        "$setsid_bin" --fork \
        "$uv_bin" run python -m dashboard.cli reconcile-sessions \
        --wait-seconds "$session_debounce" --json \
        </dev/null >> "$reconcile_log" 2>&1 || true
    else
      printf '{"ok":true,"result":"skipped_background_reconciliation","reason":"missing_setsid"}\n' \
        >> "$reconcile_log" 2>/dev/null || true
    fi
    ;;
  124|137)
    printf '{"ok":true,"result":"skipped_dashboard_timeout","timeout_seconds":"%s","saved_to":[],"openbrain_saved":false}\n' "$hook_timeout" >> "$log_path" 2>/dev/null || true
    ;;
  *)
    printf '{"ok":false,"result":"wrapper_command_failed","status":%s,"saved_to":[],"openbrain_saved":false}\n' "$status" >> "$log_path" 2>/dev/null || true
    ;;
esac

exit 0

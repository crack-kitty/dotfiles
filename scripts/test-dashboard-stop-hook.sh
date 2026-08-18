#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook="$repo_root/scripts/dashboard-stop-hook.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

missing_repo_log="$tmpdir/missing-repo.log"
DASHBOARD_HOOK_REPO="$tmpdir/no-such-dashboard" \
DASHBOARD_HOOK_UV="$tmpdir/uv" \
bash "$hook" codex "$missing_repo_log" < /dev/null
grep -q '"result":"skipped_dashboard_unavailable"' "$missing_repo_log"
grep -q '"reason":"missing_repo"' "$missing_repo_log"

repo="$tmpdir/dashboard"
mkdir -p "$repo"
missing_uv_log="$tmpdir/missing-uv.log"
DASHBOARD_HOOK_REPO="$repo" \
DASHBOARD_HOOK_UV="$tmpdir/no-such-uv" \
bash "$hook" claude-code "$missing_uv_log" < /dev/null
grep -q '"result":"skipped_dashboard_unavailable"' "$missing_uv_log"
grep -q '"reason":"missing_uv"' "$missing_uv_log"

bad_source_log="$tmpdir/bad-source.log"
if bash "$hook" bad-source "$bad_source_log" < /dev/null; then
  echo "expected bad source to fail" >&2
  exit 1
fi
grep -q '"result":"invalid_source"' "$bad_source_log"

fast_uv="$tmpdir/fast-uv"
cat > "$fast_uv" <<'EOF'
#!/usr/bin/env bash
printf '{"ok":true,"result":"fast_test"}\n'
if [[ "$*" == *"reconcile-sessions"* ]]; then
  printf 'started\n' > "$DASHBOARD_RECONCILE_MARKER"
fi
EOF
chmod +x "$fast_uv"
fast_log="$tmpdir/fast.log"
reconcile_marker="$tmpdir/reconcile.started"
DASHBOARD_HOOK_REPO="$repo" \
DASHBOARD_HOOK_UV="$fast_uv" \
DASHBOARD_HOOK_TIMEOUT_SECONDS="1" \
DASHBOARD_RECONCILE_MARKER="$reconcile_marker" \
bash "$hook" codex "$fast_log" < /dev/null
grep -q '"result":"fast_test"' "$fast_log"
for _ in $(seq 1 20); do
  [[ -s "$reconcile_marker" ]] && break
  sleep 0.05
done
grep -q 'started' "$reconcile_marker"

hanging_uv="$tmpdir/hanging-uv"
cat > "$hanging_uv" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$$" > "$DASHBOARD_HANG_PID_FILE"
trap '' TERM
while true; do
  sleep 10
done
EOF
chmod +x "$hanging_uv"
timeout_log="$tmpdir/timeout.log"
timeout_output="$tmpdir/timeout-output.log"
hang_pid_file="$tmpdir/hang.pid"
DASHBOARD_HOOK_REPO="$repo" \
DASHBOARD_HOOK_UV="$hanging_uv" \
DASHBOARD_HOOK_TIMEOUT_SECONDS="1" \
DASHBOARD_HANG_PID_FILE="$hang_pid_file" \
bash "$hook" codex "$timeout_log" < /dev/null > "$timeout_output" 2>&1
grep -q '"result":"skipped_dashboard_timeout"' "$timeout_log"
grep -q '"timeout_seconds":"1"' "$timeout_log"
test ! -s "$timeout_output"
hang_pid="$(cat "$hang_pid_file")"
if kill -0 "$hang_pid" 2>/dev/null; then
  echo "timed-out hook process survived: $hang_pid" >&2
  exit 1
fi

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

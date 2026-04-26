#!/usr/bin/env bash
# Install/sync Claude Code plugins listed in ~/.claude/settings.json.
# Idempotent: only registers marketplaces and installs plugins that are missing.
# Skips silently with a warning if the `claude` CLI is not available.
set -euo pipefail

SETTINGS="${HOME}/.claude/settings.json"

if ! command -v claude >/dev/null 2>&1; then
  echo "[claude-plugins] 'claude' CLI not found on PATH; skipping plugin sync."
  echo "[claude-plugins] Install Claude Code, then re-run dotbot to sync plugins."
  exit 0
fi

if [ ! -f "${SETTINGS}" ]; then
  echo "[claude-plugins] ${SETTINGS} not found; nothing to sync."
  exit 0
fi

# Emit "<name>\t<github-repo>" lines for each entry in extraKnownMarketplaces
# whose source is a github repo. Other source types are skipped here (the
# user can add them manually).
read_marketplaces() {
  python3 - "$SETTINGS" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    cfg = json.load(f)
for name, entry in (cfg.get("extraKnownMarketplaces") or {}).items():
    src = (entry or {}).get("source") or {}
    if src.get("source") == "github" and src.get("repo"):
        print(f"{name}\t{src['repo']}")
PY
}

# Emit one "<plugin>@<marketplace>" line per truthy entry in enabledPlugins.
read_enabled_plugins() {
  python3 - "$SETTINGS" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    cfg = json.load(f)
for ref, enabled in (cfg.get("enabledPlugins") or {}).items():
    if enabled and "@" in ref:
        print(ref)
PY
}

echo "[claude-plugins] Syncing marketplaces..."
configured_marketplaces=$(claude plugin marketplace list 2>/dev/null || true)
while IFS=$'\t' read -r name repo; do
  [ -z "${name}" ] && continue
  if printf '%s\n' "${configured_marketplaces}" | grep -qE "^[[:space:]]*❯[[:space:]]+${name}\$"; then
    echo "  ✓ ${name} already registered"
  else
    echo "  + adding ${name} (${repo})"
    claude plugin marketplace add "${repo}"
  fi
done < <(read_marketplaces)

echo "[claude-plugins] Syncing plugins..."
installed_plugins=$(claude plugin list 2>/dev/null || true)
while IFS= read -r ref; do
  [ -z "${ref}" ] && continue
  # `claude plugin list` prints "❯ name@marketplace" lines.
  if printf '%s\n' "${installed_plugins}" | grep -qE "^[[:space:]]*❯[[:space:]]+${ref}\$"; then
    echo "  ✓ ${ref} already installed"
  else
    echo "  + installing ${ref}"
    claude plugin install "${ref}"
  fi
done < <(read_enabled_plugins)

echo "[claude-plugins] Done."

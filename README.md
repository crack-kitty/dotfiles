# dotfiles

Dotfiles managed with [dotbot](https://github.com/anishathalye/dotbot).

## Install

Ubuntu/Linux:

```bash
./install
```

Windows PowerShell:

```powershell
.\install.ps1
```

The Linux installer keeps the original symlink-based setup. The Windows installer
uses Dotbot for directory setup, then copies or junctions repo-owned Claude and
Codex files while preserving live app state such as auth, sessions, caches, and
Codex runtime paths.

## Layout

- `agent-instructions/shared.md` is the canonical cross-client agent policy.
  `agent-instructions/codex.md` contains only Codex-specific routing.
- `codex/AGENTS.md` and `claude/shared-agent-policy.md` are committed generated
  outputs. The Codex entrypoint composes the shared and Codex fragments; the
  Claude bridge mirrors the shared policy at a stable user-level import path.
  `codex/*.config.toml`, `codex/hooks.json`, and `codex/agents/` contain Codex
  hooks, profiles, and worker definitions.
- `claude/CLAUDE.md` imports `~/.claude/shared-agent-policy.md` and contains only
  the Claude Code adapter. `claude/agents/`, `claude/hooks/`, and
  `claude/skills/` contain the Claude-specific runtime assets.
- Herdr's generated Claude and Codex session hooks are versioned under their
  respective runtime directories; Dotbot links the Codex hook into `~/.codex`.
- `scripts/dashboard-stop-hook.sh` is shared by Claude Code and Codex. It only
  runs the local dashboard reporter when `~/appdev/dashboard` and `~/.local/bin/uv`
  exist; other machines log a skip and exit cleanly. The reporter writes a
  source-marked OpenBrain receipt without invoking a model, under a seven-second
  wrapper backstop. After a successful receipt attempt, the hook detaches a
  serialized `dashboard reconcile-sessions` pass so Codex can enrich the same
  fact without delaying either agent's stop hook.
- `openskills` is a private submodule. Keep private package source there; the
  public repository stores only the submodule pointer and integration wiring.
- Generated Claude runtime state (sessions, cache, debug logs, tasks, telemetry,
  and similar files) is ignored even though it lives under the linked directory.
- `install.conf.yaml` is the Linux Dotbot config.
- `install.windows.conf.yaml` and `scripts/install-windows-config.ps1` are the
  Windows install path.

### Updating global agent instructions

Edit `agent-instructions/shared.md` for policy that applies to both clients and
`agent-instructions/codex.md` for Codex-only behavior. Then regenerate and check
the committed Codex entrypoint:

```bash
python3 scripts/render-agent-instructions.py
python3 scripts/render-agent-instructions.py --check
```

The repository’s versioned pre-commit hook runs an index-aware check, so a
partially staged change cannot commit source fragments with stale generated
entrypoints.

Edit `claude/CLAUDE.md` only for Claude-specific behavior; Claude imports the
committed shared-policy bridge from the stable user-level path
`~/.claude/shared-agent-policy.md`.

On Linux, Dotbot's existing symlinks make pulled changes live immediately. The
Windows installer intentionally copies entrypoint files to preserve local state,
so rerun `.\install.ps1` after pulling instruction changes.

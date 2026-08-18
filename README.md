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

- `claude/CLAUDE.md`, `claude/agents/`, `claude/hooks/`, and `claude/skills/`
  are shared Claude Code rules and assets.
- `codex/AGENTS.md`, `codex/*.config.toml`, `codex/hooks.json`, and
  `codex/agents/` are shared Codex rules, hooks, and profiles.
- Herdr's generated Claude and Codex session hooks are versioned under their
  respective runtime directories; Dotbot links the Codex hook into `~/.codex`.
- `scripts/dashboard-stop-hook.sh` is shared by Claude Code and Codex. It only
  runs the local dashboard reporter when `~/appdev/dashboard` and `~/.local/bin/uv`
  exist; other machines log a skip and exit cleanly. The reporter writes a
  source-marked OpenBrain receipt without invoking a model, under a seven-second
  wrapper backstop. After a successful receipt attempt, the hook detaches a
  serialized `dashboard reconcile-sessions` pass so Codex can enrich the same
  fact without delaying either agent's stop hook.
- `install.conf.yaml` is the Linux Dotbot config.
- `install.windows.conf.yaml` and `scripts/install-windows-config.ps1` are the
  Windows install path.

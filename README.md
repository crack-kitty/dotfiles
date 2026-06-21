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
- `codex/AGENTS.md`, `codex/*.config.toml`, and `codex/agents/` are shared
  Codex rules and profiles.
- `install.conf.yaml` is the Linux Dotbot config.
- `install.windows.conf.yaml` and `scripts/install-windows-config.ps1` are the
  Windows install path.

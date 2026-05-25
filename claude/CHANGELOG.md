## 2026-05-02: Added Session End — Mandatory section

**Added:**
- "Session End — Mandatory" section with OpenBrain Auto-Save instructions
- Requires session summary capture to OpenBrain at end of every session
- Requires project board updates when project status/scope/next-steps change

**Files:** ~/.dotfiles/claude/CLAUDE.md, ~/.dotfiles/claude/CHANGELOG.md

## 2026-05-13: Retire OpenBrain project board

**Removed:**
- "Update project board" step from Session End — Mandatory section
- "Never skip this. The user does not update the board." trailing instruction

**Why:** User retired the project board system; it wasn't working for them. OpenBrain BLOCKER rule 8d9f01fc enforces at runtime so future sessions cannot revive it.

**Files:** ~/.claude/CLAUDE.md, ~/.claude/CHANGELOG.md

## 2026-05-25: Anti-slop writing rules

**Added:**
- `Writing and Prose Quality` section to CLAUDE.md — 12 inline rules covering em-dashes, filler, AI verbs/transitions, intensifiers, hollow claims, fabricated attribution, headings
- `Facts, Sources, and Claims` subsection under `Deterministic by Default` — extends grounding with live-verification and no-failed-research-narration rules
- `no-ai-slop` skill (SKILL.md + references/ai-writing-detection.md) — adapted from realrossmanngroup/no_ai_slop_writing_rules; source attribution line at top of each file
- Skipped `rossmann-voice` skill — too opinionated and domain-specific for general use

**Why:** Prose output from Claude (commits, PR descriptions, docs, replies) drifts toward em-dashes, "delve/leverage/utilize," dramatic headings, and hollow claims. Inline rules catch the common cases in all output; skill carries the full banned-words catalog and WRONG/RIGHT examples for dedicated writing tasks.

**Files:** ~/.dotfiles/claude/CLAUDE.md, ~/.dotfiles/claude/skills/no-ai-slop/SKILL.md, ~/.dotfiles/claude/skills/no-ai-slop/references/ai-writing-detection.md, ~/.dotfiles/claude/CHANGELOG.md

## 2026-05-25: Install jq via dotbot, harden statusline PATH

**Added:**
- `install.conf.yaml` shell block that downloads jq 1.8.1 to `~/.local/bin/jq` if missing (no sudo, mirrors the gitleaks prebuilt-binary pattern; cross-platform via `uname`-derived `${os}-${arch}` suffix)
- `export PATH="$HOME/.local/bin:$PATH"` at top of `statusline-command.sh` so it finds jq regardless of how Claude Code launches the script

**Why:** Statusline silently broke (empty model, 0% context, empty rate limits) on a machine where jq wasn't installed; every `jq` subshell failed and Bash treated the empty `$(...)` as a blank field. Claude Code launches the statusline with a PATH that excludes `~/.local/bin`, so installing there alone wasn't enough — the script needs to extend PATH itself.

**Files:** ~/.dotfiles/install.conf.yaml, ~/.dotfiles/claude/statusline-command.sh, ~/.dotfiles/claude/CHANGELOG.md

## 2026-05-25: Install GitHub CLI via dotbot

**Added:**
- `install.conf.yaml` shell block that extracts gh 2.92.0 to `~/.local/bin/gh` if missing (Linux only; uses `curl | tar -xzC --strip-components=2` to pull just the binary out of the official tarball)

**Why:** gh was the actual missing piece on a fresh machine (git/node/python ship with Ubuntu, gh doesn't). Matches the gitleaks/jq prebuilt-binary user-prefix pattern, no sudo required.

**Files:** ~/.dotfiles/install.conf.yaml, ~/.dotfiles/claude/CHANGELOG.md

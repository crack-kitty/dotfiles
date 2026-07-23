## 2026-07-19: OpenSkills private pilot integration

**Added:**
- Private OpenSkills repo submodule at `~/.dotfiles/openskills`
- Claude Code pilot skill symlinks for `session-to-skill-extractor`, `agentic-harness-designer`, and `browser-qa`
- CLAUDE.md guidance to treat OpenSkills as a portable package layer across Claude Code, Codex, and Hermes
- Codex AGENTS.md guidance to load only specific OpenSkills packages and keep model routing explicit

**Why:** OpenSkills contains private Nate B. Jones source material, so the source lives in a private repo while public dotfiles carry only submodule metadata and symlink paths. Existing Dave-specific skills remain the default; pilots merge into existing skills rather than replacing them.

**Files:** ~/.dotfiles/.gitmodules, ~/.dotfiles/openskills, ~/.dotfiles/claude/skills/session-to-skill-extractor, ~/.dotfiles/claude/skills/agentic-harness-designer, ~/.dotfiles/claude/skills/browser-qa, ~/.dotfiles/claude/CLAUDE.md, ~/.dotfiles/codex/AGENTS.md, ~/.dotfiles/claude/CHANGELOG.md

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

## 2026-07-23: Add skill-fitness audit skill

**Added:**
- skill-fitness OpenSkills package: quarterly keep/merge/delete audit of the installed skill library, with deterministic inventory script

**Why:** The library grew to 38 skills with a creation gate (session-to-skill-extractor) but no deletion side. Skills that never fire or restate harness defaults cost context on every session.

**Note:** Helper scripts live in `scripts/`, not `bin/`. The damage-control hook blocks any Bash command containing `/bin/`, so a `bin/` directory would trip a false positive on every chmod and invocation.

**Files:** ~/.dotfiles/openskills/packages/skill-fitness/*, ~/.dotfiles/claude/skills/skill-fitness (symlink), ~/.dotfiles/claude/CHANGELOG.md

## 2026-07-23: Add feedback-flywheel distill skill

**Added:**
- feedback-flywheel OpenSkills package: monthly distill of history/lessons/memory/OpenBrain into proposed CLAUDE.md rule diffs, 3+ occurrence threshold

**Why:** Corrections were captured in four places (history JSONL, tasks/lessons.md, auto-memory, OpenBrain) but nothing harvested them into durable rules, so the same correction recurred across sessions.

**Files:** ~/.dotfiles/openskills/packages/feedback-flywheel/*, ~/.dotfiles/claude/skills/feedback-flywheel (symlink), ~/.dotfiles/claude/CHANGELOG.md

## 2026-07-23: Schedule the monthly flywheel distill via local cron

**Added:**
- `scripts/monthly-distill.sh` in the feedback-flywheel package: first-Monday guard evaluated in America/New_York, idempotent per day, explicit PATH for cron, headless `claude -p` run
- User crontab entry `0 9 1-7 * *` tagged `# flywheel-monthly-distill`

**Why:** A claude.ai cloud routine cannot do this job. Three of the distill's four capture surfaces (~/.claude/history, auto-memory, the report path) are local-only, so a cloud run would silently harvest OpenBrain alone. Cron cannot express "first Monday" (it ORs day-of-month with day-of-week), hence the in-script guard. CRON_TZ was deliberately NOT set at crontab scope because that would have shifted the existing graphify and dashboard jobs by four hours.

**Files:** ~/.dotfiles/openskills/packages/feedback-flywheel/scripts/monthly-distill.sh, ~/.dotfiles/openskills/packages/feedback-flywheel/SKILL.md, user crontab, ~/.dotfiles/claude/CHANGELOG.md

## 2026-07-23: Add dark-factory builder skill and pipeline

**Added:**
- dark-factory OpenSkills package: builder protocol for headless spec-to-branch runs
- ~/factory pipeline: spec inbox, factory-run runner, verify gate, report flow

**Why:** Spec-in/branch-out autonomy where the verify command is the entire quality system. Safe defaults for solo use: the runner rejects a spec whose verify already passes (a gate that cannot fail is not a gate), rejects a build that commits nothing, and lands work on a `factory/<runid>` branch unless a spec opts into `auto_merge`.

**Note:** ~/factory is machine-local, outside dotfiles. The skill syncs; the runner does not.

**Files:** ~/.dotfiles/openskills/packages/dark-factory/*, ~/.dotfiles/claude/skills/dark-factory (symlink), ~/factory/*, ~/.dotfiles/claude/CHANGELOG.md

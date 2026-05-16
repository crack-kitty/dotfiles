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

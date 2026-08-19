## Codex adapter

- Use the configured `cheap-worker` for scoped exploration, mechanical edits, read-heavy inventory, formatting, and simple checks. Keep its task bounded and require concise evidence with file references.
- Keep standard implementation in the root session unless delegation clearly reduces cost or context. Use high reasoning for architecture, security, subtle debugging, and consequential cross-file decisions.
- Treat model names and reasoning levels in `codex/config.toml`, profiles, and `codex/agents/*.toml` as the source of truth; do not duplicate version numbers here.
- Plan non-trivial work before implementation, then perform an independent review before committing or pushing.

### OpenSkills

- Portable procedure source lives in the private submodule at `~/.dotfiles/openskills`.
- When a task matches an OpenSkills package, read only that package’s `SKILL.md` and `adapters/codex/README.md`, then apply the configured routing policy.
- Do not bulk-import OpenSkills source into context. Use the configured worker only for bounded inventory, summaries, simple checks, and mechanical edits; keep architecture, security, and subtle debugging in the root session.

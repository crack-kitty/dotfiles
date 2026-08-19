@~/.claude/shared-agent-policy.md

# Claude Code adapter

## Instruction loading

- This user-level file imports Dave’s shared cross-client policy above. Project and directory `CLAUDE.md`, `CLAUDE.local.md`, and imported `AGENTS.md` files add narrower instructions; follow the most specific applicable guidance.
- Keep project-specific commands and architecture in the project’s own instruction files rather than expanding this global adapter.

## Routing

- Use `Explore` for bounded read-only discovery.
- Use `coder` for standard implementation that follows established patterns.
- Use `architect` for high-stakes design, security-sensitive work, subtle debugging, and consequential cross-file plans; it advises but does not implement.
- Use `reviewer` for an independent read-only review after meaningful changes and before committing or pushing.
- Treat model and effort values in `~/.claude/agents/*.md` as the source of truth. Do not duplicate model version numbers here.
- Keep the main session responsible for integration, user communication, unresolved trade-offs, and verification of subagent claims.

## Skills and integrations

- Claude Code skills live under `~/.claude/skills`. Load a matching skill when its description applies, and load only the references required for the task.
- Portable OpenSkills source lives in the private `~/.dotfiles/openskills` submodule. Do not copy private package source into the public dotfiles repository.
- Use connected Claude Connector and OpenBrain tools when they are the authoritative source. For Dave’s project questions, search both available sources before the web. Do not hard-code connector URLs or claim a capture succeeded without a tool result.

## Configuration maintenance

- When changing Claude Code global configuration, skills, commands, agents, or hooks in this repository, append a concise dated entry to `~/.claude/CHANGELOG.md` describing what changed, why, and which files were affected.

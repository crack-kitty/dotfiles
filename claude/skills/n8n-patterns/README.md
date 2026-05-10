# n8n-patterns

A Claude Code skill that encodes an n8n editing discipline and recurring gotchas. Designed to trigger any time you (or Claude Code) work with n8n workflows, automations, or scheduled jobs.

## What's in here

```text
n8n-patterns/
├── SKILL.md                          # Lean entry point (always loaded as metadata)
└── references/                       # Loaded only when SKILL.md points to them
    ├── safe-editing-rules.md         # Golden Rule, 13 Hard Rules, risk classes, side-effect list
    ├── node-gotchas.md               # Loop Over Items, local-LLM thinking field, multi-step MCPs, etc.
    ├── expression-scanning.md        # Patterns to grep for downstream impact
    ├── validation-checklist.md       # Post-edit sanity checks
    └── project-patterns.md           # Project-specific conventions, Discord alerter patterns, reusable flows
```

## Install

Drop the entire `n8n-patterns/` folder into your skills directory:

```bash
# For your dotfiles-managed setup
cp -r n8n-patterns ~/.dotfiles/claude/skills/

# Then commit & sync (your usual workflow)
cd ~/.dotfiles
git add claude/skills/n8n-patterns
git commit -m "Add n8n-patterns skill"
git push
```

On other servers:
```bash
cd ~/.dotfiles && git pull && ./install
```

## How it triggers

Claude Code will load this skill automatically when:
- The user mentions n8n, a specific n8n node type, or a workflow file
- The user references one of their workflow projects
- The conversation involves automation, scheduled jobs, or workflow editing — even if "n8n" isn't said explicitly

The description in SKILL.md is intentionally "pushy" per Anthropic's skill-authoring guidance — skills tend to under-trigger by default.

## How it's structured

Anthropic's skill system uses **progressive disclosure**:
1. At session start, only the `name` and `description` from SKILL.md frontmatter are in Claude's system prompt — almost zero context cost.
2. When the description matches the current task, Claude reads the SKILL.md body.
3. The body points to specific reference files only when their topic is relevant.

So even though this bundle is ~5,600 words total, only ~1,400 words are read for typical n8n work, and the deep references only load when their topic comes up.

## Updating

If you discover a new gotcha:
1. Add it to the right reference file (or create a new one)
2. If it's high-frequency, mention it in SKILL.md too so it's seen on every load
3. Keep SKILL.md under 2,000 words — push detail to references

If you find yourself wanting to add a recurring pattern that's *not* n8n-specific, it probably belongs in a different skill — don't expand this one beyond its lane.

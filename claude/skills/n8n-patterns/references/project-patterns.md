# Workflow Patterns

Project-specific conventions and reusable patterns for the user's active n8n workflows. Load this when work touches one of these systems.

## Flight-Monitoring Workflow

**What it is**: A self-hosted fare-monitoring system that tracks a fixed set of routes and posts alerts on price changes.

**Stack**:
- A flight-search library called via MCP
- n8n orchestration
- Postgres database (project-specific)
- Google Sheets (alert log / human-readable view)
- Discord (alerts)

**Active workflows**:
- **Scheduled collector workflow** — pulls fares for all tracked routes on a schedule, writes to the project database
- **Alerting workflow** — checks for price drops or fare anomalies, posts to Discord
- **Route-specific monitors** — deeper intelligence for high-interest routes

**MCP knowledge**: Some MCPs in this stack require multi-step session init — do not collapse it into a single call. Watch for parameter casing requirements (e.g., enum values that must be uppercase) and parameter rejections (some valid-looking parameters error when included). Filter results downstream when in doubt.

**Discord alert formatting**:
- Bold the destination
- Include current price, previous price, and percent change
- Include direct booking link if available
- Use emoji sparingly — alert-noise is not appreciated

## Trading Workflow

**What it is**: An autonomous paper-trading bot using the Anthropic API + a brokerage API.

**Cycle**: every 30 minutes during US market hours.

**Pipeline**:
1. Pull account state, current positions, news, active stocks
2. Send context to Claude (Anthropic API node) for a JSON trade decision
3. Pass decision through **Safety Gate** (Code node)
4. If approved, execute trade via the brokerage API
5. Post result to Discord

**The Safety Gate is non-negotiable.** It enforces hard limits on trade count, position size, and asset class. **Never bypass or weaken the Safety Gate** — even a "small" change should not relax these limits without explicit user sign-off.

## Scheduled Workflow Convention

All of the user's scheduled workflows must:
1. Have `settings.timezone = "America/New_York"` set at the workflow level
2. Use Schedule Trigger (not Cron node — Schedule Trigger is the modern equivalent)
3. Log execution start to a known location (Postgres, Sheets, or Discord depending on workflow)
4. Have an error workflow or `continueOnFail` strategy on critical nodes

When auditing scheduled workflows, the checklist is:
- [ ] Workflow timezone explicitly set?
- [ ] Schedule Trigger node present and configured?
- [ ] First node after trigger handles "no data" / "API down" gracefully?
- [ ] Final side-effect node (alert) wraps in try/catch or has retry?

## Discord Alerter Pattern

Reusable structure for any workflow that posts alerts to Discord:

```text
[Source nodes]
       ↓
[Format Message]   ← Code node or Set node, builds final text
       ↓
[Discord Webhook]  ← side-effect, set continueOnFail=true so a failed alert doesn't kill the workflow
       ↓
[Log Result]       ← Postgres or Sheets append, for audit trail
```

Conventions:
- Discord webhook URL stored as credential, never hardcoded
- Message length kept under 2000 chars (Discord limit)
- For long content, use embeds rather than plain text

## Postgres Patterns

For project databases:

**Insert with conflict handling** (n8n re-runs are common; avoid duplicates):
```sql
INSERT INTO snapshots (source_id, recorded_at, payload)
VALUES ($1, $2, $3)
ON CONFLICT (source_id, recorded_at) DO NOTHING
```

**Query then loop pattern**:
- Postgres node returns an array of items (one per row)
- Wire the output directly into Loop Over Items if processing per-row
- Or wire into a Code node for set-level operations

**Schema changes**:
- Coordinate schema migrations with workflow changes — never deploy a workflow that references a column before the column exists
- Treat existing tables as a contract; adding columns is safe, renaming/removing requires sweeping the workflow set

## OpenBrain Project Tags for n8n Work

When saving facts/incidents/rules from n8n work, tag with `n8n` plus the workflow name for searchability. Use the configured project name for the workflow being modified, or `n8n` as a default for cross-cutting patterns not tied to a specific workflow.

## The Non-Coder Translation Layer

The user is a non-coder. When working on their n8n workflows:

- **Always explain what each node does in one sentence** when introducing it for the first time in a session.
- **Avoid programming-language jargon** ("currying," "monad," "destructuring") when plain English ("pull these fields out") works.
- **Show the workflow structure as a diagram or numbered list** before showing JSON.
- **For Code nodes, comment generously.** The user will read the comments to understand the logic.
- **Prefer Set/Edit Fields nodes over Code nodes** when both can do the job — they're easier to read and modify later.
- **When something requires JavaScript, walk through it line by line** in plain English the first time.

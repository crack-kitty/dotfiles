# Dave's Workflow Patterns

Project-specific conventions and reusable patterns for Dave's active n8n workflows. Load this when work touches one of these systems.

## FlightCheck

**What it is**: Self-hosted United Airlines fare monitoring system. Tracks ~150 destinations from Albany (ALB) through hubs ORD, IAD, DEN.

**Stack**:
- `fli` library (Python, called via MCP)
- n8n orchestration
- Postgres database: `flightcheck-db`
- Google Sheets (alert log / human-readable view)
- Discord (alerts)

**Active workflows**:
- **Daily Collector** — scheduled, pulls fares for all tracked routes, writes to `flightcheck-db`
- **Alert Engine** — checks for price drops or fare anomalies, posts to Discord
- **BOI Monitor** — deep route intelligence specifically for Albany → Boise (high personal interest route)

**Critical fli MCP knowledge**:
- Three-step session init pattern is required — do not collapse to a single call
- `cabin_class` must be `'ECONOMY'` (uppercase). Lowercase or title case fails silently
- `max_results` is **not** a valid parameter; including it errors. Filter downstream
- Hubs Dave routes through: ORD, IAD, DEN

**Discord alert formatting** (FlightCheck convention):
- Bold the destination
- Include current price, previous price, and percent change
- Include direct booking link if available
- Use emoji sparingly — Dave doesn't like alert-noise

## Stock Trading Bot

**What it is**: Autonomous trading bot using Anthropic API + Alpaca paper trading on a ~$50k paper account.

**Cycle**: every 30 minutes during US market hours.

**Pipeline**:
1. Pull account state, current positions, news, active stocks (via Alpaca + news API)
2. Send context to Claude (Anthropic API node) for a JSON trade decision
3. Pass decision through **Safety Gate** (Code node)
4. If approved, execute trade via Alpaca
5. Post result to Discord

**The Safety Gate is non-negotiable. It enforces**:
- Max 5 trades per cycle
- Max 50 shares per order
- No crypto

**Never bypass or weaken the Safety Gate.** Even a "small" change should not relax these limits without explicit Dave sign-off.

**Planned three-tier expansion** (not yet built):
- Tier 1: Buffett-style long-term
- Tier 2: Swing trading
- Tier 3: Momentum
- Multi-model consensus (Claude + Gemini + GPT-4o)
- Parallel paper accounts for empirical comparison

When Dave asks about "the trading bot," confirm which tier he means before assuming.

## Scheduled Workflow Convention

All of Dave's scheduled workflows must:
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

For `flightcheck-db` and similar:

**Insert with conflict handling** (n8n re-runs are common; avoid duplicates):
```sql
INSERT INTO fare_snapshots (route_id, snapshot_at, price, cabin)
VALUES ($1, $2, $3, $4)
ON CONFLICT (route_id, snapshot_at) DO NOTHING
```

**Query then loop pattern**:
- Postgres node returns an array of items (one per row)
- Wire the output directly into Loop Over Items if processing per-row
- Or wire into a Code node for set-level operations

**Schema changes**:
- Coordinate schema migrations with workflow changes — never deploy a workflow that references a column before the column exists
- For `flightcheck-db`, treat existing tables as a contract; adding columns is safe, renaming/removing requires sweeping the workflow set

## OpenBrain Project Tags for n8n Work

When saving facts/incidents/rules from n8n work:

| Project | Use for |
|---|---|
| `flightcheck` | Daily Collector, Alert Engine, BOI Monitor, fli MCP knowledge |
| `trading-bot` | Stock trading bot, Safety Gate logic, Anthropic API patterns |
| `n8n` (default) | Cross-cutting n8n patterns not tied to a specific workflow |
| `homelab` | n8n instance config, server-side concerns |

Always tag with `n8n` plus the workflow name for searchability.

## The Non-Coder Translation Layer

Dave is a non-coder. When working on his n8n workflows:

- **Always explain what each node does in one sentence** when introducing it for the first time in a session.
- **Avoid programming-language jargon** ("currying," "monad," "destructuring") when plain English ("pull these fields out") works.
- **Show the workflow structure as a diagram or numbered list** before showing JSON.
- **For Code nodes, comment generously.** Dave will read the comments to understand the logic.
- **Prefer Set/Edit Fields nodes over Code nodes** when both can do the job — they're easier for him to read and modify later.
- **When something requires JavaScript, walk through it line by line** in plain English the first time.

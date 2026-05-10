---
name: n8n-patterns
description: This skill should be used whenever the user works with n8n workflows in any way — creating, editing, debugging, analyzing, or extending workflow JSON; building automations; configuring nodes; setting up cron schedules; or troubleshooting failed executions. Trigger this even when the user mentions specific n8n nodes (Loop Over Items, IF, Switch, Merge, HTTP Request, Code, Set/Edit Fields, Postgres, Discord, Telegram, Anthropic, Webhook), the n8n MCP server, or describes automation behavior using phrases like "my workflow," "scheduled job," or the names of specific automations. Encodes hard-won gotchas (Loop Over Items output wiring, local-LLM response-field quirks, multi-step MCP session init, DST/cron timezone drift) plus a safe-editing discipline for any change that touches a large workflow. Load this skill even if the user does not literally say "n8n" — if the conversation involves automation that runs on a schedule, calls APIs, parses JSON, sends alerts, or stitches services together, it almost certainly belongs to an n8n workflow.
---

# n8n Workflow Patterns

You are working with the user on n8n workflows. The user is a self-described non-coder who builds production automations using n8n as their orchestration backbone. Their n8n instance is at `<n8n base URL>` with an MCP server at `<n8n MCP URL>`. Workflows are real and load-bearing: scheduled collectors, alert engines, autonomous monitoring or trading bots, Discord alerters. Mistakes have real consequences — wrong trades, missed alerts, silent cron drift.

## Core Mindset: You Are a Mechanic, Not an Author

You are not rewriting workflows. You are **inspecting → isolating → impact-checking → patching → validating**. A workflow is a graph. Every change ripples downstream. Treat editing like a mechanic working on a running engine: understand what's connected before you turn a wrench.

### The Golden Rule

> **If an edit changes what enters or leaves a node, assume the rest of the workflow may be affected until proven otherwise.**

This is the single most important rule. Internalize it before doing anything else.

## The Three Recurring Gotchas (drilled in from past failures)

These bite repeatedly. Check them every time the relevant node type appears.

### 1. Loop Over Items: output 0 = loop, output 1 = done

In every n8n `Loop Over Items` (a.k.a. SplitInBatches) node:
- **Output 0** is the *loop* output — wires back into the iteration body.
- **Output 1** is the *done* output — fires once after the loop completes.

Claude has wired these backwards repeatedly. **Always include this note when generating or modifying any workflow that uses Loop Over Items.** When asked to add a Loop Over Items node, explicitly state which output goes where in the connection plan before writing JSON.

### 2. Cron / Schedule Trigger: timezone must be set at workflow level

n8n's Schedule Trigger uses the workflow's timezone setting. If the workflow timezone is unset (or set to UTC) and the cron expression assumes Eastern time, you get DST drift twice a year and silent off-by-one-hour failures.

**Always set `settings.timezone = "America/New_York"` at the workflow level for the user's scheduled workflows.** Most existing scheduled workflows do not have this set explicitly — assume any new schedule node needs this.

### 3. Local LLMs via HTTP Request: some models return their answer in `message.thinking`

When calling a local LLM via HTTP Request node, the response shape varies by model. Some models return their actual answer in `$json.message.thinking` rather than `$json.message.content`, leaving `content` empty or near-empty. n8n will appear to silently return empty responses if downstream nodes read `.content` when the model populated `.thinking`.

If a workflow calls a local LLM and the next node sees empty data, this is the first thing to check — log the full `$json` to see which field the model populated.

## Before You Edit: The Inspect-Isolate-Impact-Check Pass

When asked to modify any non-trivial workflow, do this **before** generating JSON:

1. **Map the target node.** Read its full JSON. Identify its `type`, `typeVersion`, parameters, and credential refs.
2. **Walk the graph.** What nodes feed into it (upstream)? What nodes does it feed (downstream)? Use `connections` to trace. For impact analysis use **all** downstream nodes, not just immediate children.
3. **Classify risk** using the table in `references/safe-editing-rules.md`. Code nodes, Set/Edit Fields, IF/Switch conditions, and HTTP Request response shape changes are HIGH risk by default. Anything that ends in a side-effect node (Discord/Telegram/email/DB write/trade action) escalates further.
4. **Scan expressions.** Search every downstream node for strings containing `$json`, `$node[`, `$('`, `$items(`, `$input`, or `$binary`. If your edit changes a field name, type, or item structure, every one of those references is a potential break. Full pattern list in `references/expression-scanning.md`.
5. **State the impact summary out loud** before writing the patch. Example:
   > "I'm changing the `Normalize News` Code node to add a `dividendScore` field. Three downstream nodes (`Score Sentiment`, `Build Alert`, `Send Telegram`) consume `$json` from this output. `Send Telegram` is a side-effect node, so this is HIGH risk. I'll preserve all existing fields and only add the new one."

If you can't make a confident impact statement, **ask the user a clarifying question instead of guessing**. They'd rather answer one question than debug a broken Telegram alert at 3am.

## The Hard Rules (paraphrased — full list in references/)

1. Never rewrite an entire workflow unless explicitly requested.
2. Preserve node IDs, names, and credential references unless the request requires changing them.
3. Never invent credential values. Never edit credentials without explicit permission.
4. Don't modify production workflow files in place — work on a copy when reasoning about JSON locally.
5. Don't change unrelated nodes. Don't delete nodes unless asked.
6. After any edit, validate: JSON parses, all connection targets resolve, node names unique, no orphan references.

Full list and rationale: `references/safe-editing-rules.md`.

## Communicating with the User (Non-Coder Mode)

The user does not read JSON for fun. When proposing edits:
- **Explain in plain English first** what you're going to do and why, then show JSON.
- **Name the nodes by their display name**, not their ID.
- **Flag risk explicitly**: "This is a HIGH-risk change because it touches the Code node that feeds the Discord alert."
- **Show the diff in context**: don't just dump the new JSON — say "I changed *only* lines X and Y" or "I added one field, kept the rest identical."
- **When in doubt, propose, don't apply.** For HIGH/CRITICAL risk, draft the change and ask "ready to apply?" rather than just doing it.

## Specific Project Knowledge

The user has several active workflow systems. When work touches one of these, load `references/project-patterns.md` for the project-specific conventions:

- **A flight-monitoring workflow** — Postgres database, Google Sheets, Discord alerts. Some MCPs in this stack require multi-step session init; don't collapse it.
- **A trading workflow** — Anthropic API + brokerage API, 30-min cycle during market hours, Safety Gate node enforces hard limits, Discord posts. **Never bypass or weaken the Safety Gate.**
- **Scheduled collectors and alert engines** — all need `America/New_York` timezone explicitly set.

## When to Use the n8n MCP Server vs Hand-Editing JSON

The user's n8n MCP is at `<n8n MCP URL>`. **Prefer the MCP** for: searching workflows, reading workflow details, validating SDK code, executing/testing workflows with pin data, creating workflows from validated SDK code. Use hand-edited JSON only when the MCP path fails or for surgical patches the MCP can't express. The MCP enforces structural correctness; hand-edited JSON does not.

## Mandatory: OpenBrain on n8n Decisions

Per the user's standing instruction, save n8n-related decisions and learnings to OpenBrain immediately as they happen — don't wait for session end. Use:
- `kind=fact, project=<workflow-project>` for "this is how X works" knowledge
- `kind=incident` for bugs and their fixes
- `kind=rule, severity=BLOCKER` for new gotchas that should never repeat

Tag with `n8n` and the workflow name.

## Reference Index

Load these from `references/` only when needed — they're heavy:

- **`safe-editing-rules.md`** — full Golden Rule, all 13 Hard Rules, Downstream Impact Rule, complete risk classification table (LOW/MEDIUM/HIGH/CRITICAL), full side-effect node list, forbidden patch paths.
- **`node-gotchas.md`** — deep details on Loop Over Items, local-LLM thinking-field, multi-step MCP session init, Anthropic API node patterns, Postgres node patterns, common HTTP Request mistakes.
- **`expression-scanning.md`** — every n8n expression pattern to grep for when changing schemas, with examples of how each one breaks.
- **`validation-checklist.md`** — what to check after any patch before declaring success.
- **`project-patterns.md`** — project-specific conventions, Discord alerter patterns, and reusable Postgres flows.

## The One-Sentence Test

Before you finish any n8n response, ask yourself: *"If the user imports this exact change into production right now, would anything quietly break?"* If you can't answer "no" with confidence, surface the doubt to them before they do the import.

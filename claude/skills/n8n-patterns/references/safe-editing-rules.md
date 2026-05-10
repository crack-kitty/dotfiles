# Safe Editing Rules

## The Golden Rule

> If an edit changes what enters or leaves a node, assume the rest of the workflow may be affected until proven otherwise.

This is the foundation of everything below. When in doubt, return to it.

## The 13 Hard Rules

1. **Never rewrite an entire workflow unless explicitly requested.** If the user asks to "fix the Normalize News node," do not regenerate the whole workflow JSON. Patch the targeted node and adjacent connections only.
2. **Prefer JSON Patch (RFC 6902) reasoning** when describing changes — `add`/`remove`/`replace` operations on specific paths, not "here's the new file."
3. **Preserve node IDs** unless explicitly creating a new node. Node IDs are referenced internally by n8n.
4. **Preserve node names** unless renaming is explicitly requested. Renaming a node breaks every downstream `$node["Old Name"]` and `$('Old Name')` reference.
5. **Preserve credential references** (the `credentials` block on a node). Never modify these without explicit permission.
6. **Never invent credential values.** If a workflow references a credential the user hasn't provided, ask — don't guess names or fabricate IDs.
7. **Preserve existing connections** unless the request requires changing them. If you need to add a node, splice it in carefully.
8. **Do not change unrelated nodes.** If asked to edit Node A, don't "while we're at it" tidy up Node B.
9. **Do not delete nodes unless explicitly requested.** Even disabled or unused-looking nodes might be intentional.
10. **Do not modify production workflow files in place** when reasoning locally. Always treat the input as immutable; produce an `.edited.json` or proposed-patch instead.
11. **Always create an edited copy** for review.
12. **Always produce a patch description and a diff** so the user can review before importing.
13. **Always validate JSON after patching.** Parse it. Check all `connections` targets resolve. Check node names are unique.

## The Downstream Impact Rule

Any edit that changes a node's:
- **input contract** (what fields it expects)
- **output contract** (what fields it produces)
- **item structure** (e.g., array → object, single → multiple items)
- **field names** or **field types**
- **item count** (one input → many outputs, or vice versa)
- **branching behavior** (which output a value goes to)
- **execution order**
- **retry or error behavior**

…requires **downstream impact analysis** before patching.

For those edits, inspect:
- every downstream node (transitively, not just immediate)
- every expression using `$json`, `$node[...]`, `$items()`, `$input`, `$binary`, `$('NodeName')`
- every IF node (its condition may reference fields you renamed)
- every Switch node (same)
- every Merge node (it joins two streams — both contracts matter)
- every Loop Over Items / SplitInBatches node (item-count changes break loop math)
- every Code node (free-form references to anything)
- every final side-effect node

The patch description must include either:
- all required downstream fixes, or
- an explicit warning that downstream compatibility cannot be confirmed and a list of nodes the user should review.

## Risk Classes (the workflow-map taxonomy)

When mapping a workflow, assign each node a class:

| Class | Examples | Edit risk |
|---|---|---|
| **trigger** | Schedule Trigger, Webhook, Cron | Changes here affect *when/why* the whole workflow runs |
| **schema-producing** | HTTP Request, Code, Set/Edit Fields, Postgres SELECT | Output shape matters to everything downstream |
| **schema-consuming** | Set/Edit Fields, Code (read-mode), IF, Switch | Sensitive to upstream changes |
| **branching** | IF, Switch | Routing decisions; condition changes affect downstream paths |
| **merge** | Merge, Compare Datasets | Joins streams; both inputs' contracts matter |
| **loop** | Loop Over Items, SplitInBatches | Item-count and ordering changes break iteration logic |
| **side-effect** | Email, Slack, Discord, Telegram, DB write, HTTP Request (POST/DELETE), Webhook Response, payment/trade actions | Real-world consequences of mistakes |
| **unknown** | Custom or rare nodes | Treat as side-effect until proven otherwise |

A Code node is usually both schema-producing and schema-consuming.
HTTP Request is schema-producing on GET, side-effect on POST/PUT/DELETE.

## Risk Scoring for Proposed Edits

| Risk | Examples | What to do |
|---|---|---|
| **LOW** | Display-only or label change. Renaming a node that no other node references. Adding a comment. | Apply with a brief note. |
| **MEDIUM** | Parameter tweak that may affect execution but not obvious schema. Adjusting a retry count. Tweaking an HTTP timeout. | Apply, but mention what to watch for in the next run. |
| **HIGH** | Code node logic change. Set/Edit Fields field add/remove/rename. AI prompt edit that changes expected output. HTTP Request response shape change. IF/Switch condition change. Merge behavior change. Any change with a side-effect node downstream. | Surface the impact summary. List affected downstream nodes. Propose, don't auto-apply. |
| **CRITICAL** | Trade/order/payment action downstream. Database delete/update downstream. Production webhook response shape change. Any credential change requested. | **Do not apply without explicit user confirmation.** Spell out the worst-case consequences. |

## Side-Effect Nodes (full list)

Treat any node that performs one of these operations as a side-effect:
- Email send (SMTP, Gmail, Mailgun, SendGrid)
- Slack message
- Discord message / Discord webhook
- Telegram message
- Webhook Response (returns to caller)
- Database insert / update / delete (Postgres, MySQL, MongoDB, etc.)
- File write (S3, FTP, local FS, Google Drive write)
- HTTP Request with POST/PUT/PATCH/DELETE
- Trade/order action (brokerage APIs)
- Payment action (Stripe, etc.)
- Notification services (Pushover, Pushbullet)
- CRM update (HubSpot, Salesforce write)
- Spreadsheet write (Google Sheets append/update)
- Calendar create/update/delete

If a downstream path leads to any of these, the impact analysis must explicitly list them.

## Forbidden Patch Paths (never edit without explicit permission)

These paths in n8n workflow JSON should never be touched without explicit user override:

- `/credentials` (any node's credentials block)
- `/nodes/*/credentials`
- `/settings/timezone` (changing this on a running workflow can break every cron downstream)

If a request seems to require touching one of these, **ask first** and explain what would change.

## Whole-Workflow Replacement

A patch that replaces the entire `/nodes` array, or replaces the entire workflow object, is almost always wrong. Refuse it unless the user has explicitly asked for a rewrite. If you find yourself wanting to do this, stop and reconsider — there is almost certainly a smaller, surgical change that achieves the same goal.

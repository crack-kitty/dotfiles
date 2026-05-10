# Node-Level Gotchas

This is the "scar tissue" file — patterns Claude has gotten wrong on the user's workflows in the past. Check here whenever the relevant node type appears.

## Loop Over Items (SplitInBatches)

The single most common mistake. Wire the outputs correctly:

- **Output 0** — *loop* output. This is what fires on each iteration. Connect this to whatever processes one batch.
- **Output 1** — *done* output. This fires once after all iterations complete. Connect this to whatever runs after the loop ends (final summary, cleanup, single Discord post).

```text
Loop Over Items
├── output 0 (loop) ──→ [process one batch] ──→ back to Loop
└── output 1 (done) ──→ [final step]
```

When generating new workflows that use Loop Over Items, **state the output mapping in the connection plan in plain English before writing the JSON**. This forces a correctness check.

Common mistakes to avoid:
- Wiring "process this batch" to output 1 (causes nothing to happen until the loop is "done," but the loop never gets data, so it's never done — silent hang)
- Not connecting output 1 at all (final step never runs)
- Sending the post-processing back into the loop body (infinite re-iteration)

## Local LLM via HTTP Request — some models return their answer in `message.thinking`

When calling a local LLM via HTTP Request node, the response shape varies by model. Most models populate `$json.message.content` (the conventional field). Some models put their actual answer in `$json.message.thinking` and leave `content` empty or near-empty. n8n HTTP Request nodes will appear to silently return nothing if downstream nodes read `.content` when the model populated `.thinking`.

**When debugging a workflow that calls a local LLM and gets empty downstream data, the first check is which field the model populates.** If unsure, log the full `$json` to see the shape.

## MCPs with Multi-Step Session Init

Some MCP integrations require a precise multi-step session initialization pattern. Skipping or reordering steps causes silent failures. When generating workflows that call such MCPs, follow the documented init pattern as-is — don't collapse it into a single call. If parameter casing is documented (e.g., enum values that must be uppercase), follow it exactly; deviations often fail silently. Some valid-looking parameters are rejected by certain MCPs — when in doubt, omit and filter results downstream.

## Schedule Trigger — DST drift

n8n's Schedule Trigger uses the **workflow-level timezone setting** for cron interpretation. If unset, it defaults to the n8n instance's timezone (often UTC).

Most of the user's existing scheduled workflows do not have `settings.timezone` set explicitly — they run on UTC and have silent off-by-one-hour drift twice a year at DST transitions.

**Default to setting `settings.timezone = "America/New_York"` on every workflow that uses Schedule Trigger.** Verify the existing setting before adding/modifying a Schedule Trigger node.

To set this in JSON, look at the workflow root:

```json
{
  "name": "...",
  "nodes": [...],
  "connections": {...},
  "settings": {
    "timezone": "America/New_York",
    "executionOrder": "v1"
  }
}
```

If `settings` is missing or doesn't contain `timezone`, add it.

## Anthropic API Node

When workflows call Claude via the Anthropic API node:
- The response content lives in `$json.content[0].text` (assuming a single text block).
- If the model returns JSON, downstream parsing should be defensive — wrap in a Code node with try/catch on `JSON.parse`. Models can return preamble or trailing text even with strict prompts.
- If the workflow has a Safety Gate Code node between the model output and any side-effect action (trade, payment, irreversible API call), **never bypass or weaken the Safety Gate** — even on a "small" change.

## Postgres Node

- Use parameterized queries. Never interpolate user-controlled strings into SQL via expression substitution.
- For inserts that may conflict, prefer `ON CONFLICT DO NOTHING` or `ON CONFLICT DO UPDATE` — n8n re-runs are common during debugging and you don't want duplicate rows.
- For project databases with stable schemas, if a Code node downstream references columns by name, schema changes need migration coordination.

## HTTP Request — common mistakes

- **POST without proper headers**: Default content-type may not match what the API expects. JSON APIs need `Content-Type: application/json`.
- **Auth headers via expressions**: If using an expression to inject a credential, double-check the expression evaluates to a string, not an object.
- **Pagination**: n8n's HTTP Request has built-in pagination support. Don't roll your own with Loop Over Items unless the API does something nonstandard.
- **Response format**: If the API returns a list at the top level (e.g., `[{...}, {...}]`), set the response format accordingly so n8n splits items correctly.

## Set / Edit Fields Node

- Adding a field is generally safe.
- **Removing a field** is HIGH risk if any downstream node references it via `$json.<fieldname>`.
- **Renaming a field** is effectively a remove + add — every downstream reference must be updated.
- "Keep Only Set" mode discards everything not listed. Use with care; it's a silent way to drop fields downstream nodes need.

## IF and Switch Nodes

- Condition expressions reference upstream `$json` fields. Renaming or restructuring upstream output breaks the condition silently — items just route to "false" by default.
- Switch nodes have an explicit "fallback" output (output 3, by default). Confirm what's connected to it.
- IF/Switch don't transform data; they only route it. The same `$json` shape exits as entered.

## Merge Node

- Two input streams. Both contracts matter for downstream consumers.
- "Append" mode concatenates; "Merge By Key" joins on a field; "Choose Branch" picks one stream entirely.
- If the two inputs have different field sets, downstream code must handle missing fields defensively.

## Code Node

The most flexible node, the easiest to break with downstream changes. A Code node is both schema-consuming (reads `$input` / `$json`) and schema-producing (returns items).

- Code nodes can return a single item, an array of items, or `$input.all()`. Make sure the return shape matches downstream expectations.
- **Always return arrays of objects** unless you have a specific reason otherwise: `return items.map(item => ({ json: { ... } }))`.
- Code edits are HIGH risk by default — they can change output shape silently.

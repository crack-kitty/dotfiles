# Validation Checklist

Run through this after any patch, before declaring the edit complete. If any item fails, fix it before handing off to the user.

## Structural Checks

- [ ] **JSON parses.** The edited workflow file is valid JSON.
- [ ] **Workflow has a `nodes` array.** Top-level structure is intact.
- [ ] **All node names are unique.** No two nodes share the same `name`.
- [ ] **All node IDs are unique.** No two nodes share the same `id`.
- [ ] **Every `connections` entry resolves.** For each connection source and target, the named node exists in the `nodes` array.
- [ ] **Every node has `name`, `type`, `position`, `parameters`.** No required field is missing.
- [ ] **No undefined connection targets.** A `connections` block referencing a deleted node is invalid.
- [ ] **The patch did not replace the entire workflow.** If the diff shows the whole file replaced, the patch is wrong — back out and try again surgically.

## Credential & Safety Checks

- [ ] **No credential values were inserted.** Credential blocks should only contain `id` and `name` references, never secret values.
- [ ] **No credential references were silently changed.** If a node's `credentials` field changed, was that explicit?
- [ ] **`/settings/timezone` was not silently modified.** If the workflow had a timezone, it still has the same one (unless the change was requested).
- [ ] **Forbidden paths untouched.** `/credentials`, `/nodes/*/credentials`, and `/settings/timezone` were not changed without explicit permission.

## Schema-Impact Checks

- [ ] **If field names changed in the target node's output, every downstream expression referencing them was updated.** (Or: an explicit warning was raised that they need review.)
- [ ] **If a node was renamed, every `$node["..."]` and `$('...')` reference in every other node was updated.**
- [ ] **If item count behavior changed** (e.g., a Code node now returns multiple items where it returned one), every downstream Loop/Merge/IF was reviewed.
- [ ] **If a Code node returns a non-array, downstream nodes can handle it.** n8n strongly prefers arrays of `{ json: ... }` objects.

## Branching & Control Flow Checks

- [ ] **IF/Switch conditions still reference fields that exist.** Renamed/removed fields cause silent "always false" routing.
- [ ] **Loop Over Items output 0 (loop) and output 1 (done) are wired correctly.** This is the #1 recurring trap.
- [ ] **Merge node inputs come from the streams the user expects.** Both contracts are handled.
- [ ] **Error workflow / continueOnFail settings were not changed unintentionally.**

## Side-Effect Awareness

- [ ] **Every side-effect node downstream of the edit was identified.** (Discord, Telegram, DB write, HTTP POST, trade action, etc.)
- [ ] **The user has been told which side-effect nodes might be affected.**
- [ ] **For CRITICAL risk edits, explicit confirmation was received before applying.**

## Diff & Communication Checks

- [ ] **A human-readable diff was produced** (`git diff --no-index original.json edited.json` works even outside a Git repo).
- [ ] **The change was explained in plain English**, not just JSON.
- [ ] **The risk class (LOW/MEDIUM/HIGH/CRITICAL) was stated.**
- [ ] **Affected downstream nodes were listed by name.**

## Save & Memory Checks

- [ ] **For non-trivial changes, a fact was saved to OpenBrain** — what changed, why, and any new gotcha discovered.
- [ ] **For new gotchas that should never repeat, a `kind=rule, severity=BLOCKER` was added.**
- [ ] **The original workflow file was not overwritten in place** unless the user explicitly asked.

## Final Question

> *"If the user imports this exact change into production right now, would anything quietly break?"*

If you cannot answer "no" with confidence, **do not declare the edit complete**. Surface the doubt.

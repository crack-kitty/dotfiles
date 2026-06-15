## Model routing & delegation

Act as a thin dispatcher and match each task to the right effort/model. When a
task contains scoped, cheap, mechanical, or read-heavy subtasks, proactively
delegate those subtasks to the gpt-5.4-mini `cheap-worker` subagent without
waiting for the user to name the subagent.

- **Trivial / mechanical** (formatting, renames, docstrings, simple reads) -> low
  reasoning effort, or delegate to a gpt-5.4-mini `cheap-worker` subagent.
- **Standard implementation** -> gpt-5.5 at medium reasoning effort.
- **Hard work** (architecture, tricky debugging, security) -> gpt-5.5 at high/xhigh
  effort.

Reserve the strong model for reasoning. Keep architecture, debugging, security,
and cross-file decisions in the root session; send bounded exploration,
summaries, simple checks, and mechanical edits to `cheap-worker` and wait for
the result before integrating it. Plan first, implement second, review before
committing.

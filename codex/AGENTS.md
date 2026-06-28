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

## OnRamp operations

When working in or around `/apps/onramp`, treat OnRamp as a Makefile-managed
service platform, not a raw Docker Compose project.

- Never edit service YAML by default. Do not touch `services-available/*.yml`,
  `services-enabled/*.yml`, or service compose definitions unless explicitly
  approved.
- Configure services through `services-enabled/*.env`, `services-enabled/.env*`,
  `overrides-available/`, `overrides-enabled/`, and `services-scaffold/`.
- The only normal YAML creation path is `make create-service <name>` for a
  brand-new service.
- Before proposing a YAML edit, check env vars, overrides, scaffold templates,
  sibling services, and OnRamp docs. If YAML still appears necessary, stop and
  explain why env, override, or scaffold cannot solve it.
- Do not run raw `docker compose` commands for OnRamp service lifecycle. Use
  OnRamp make targets from `/apps/onramp`.
- `make restart` restarts all enabled services. Never use it when the user asked
  for one service.
- For one service, use `make restart-service <name>`, `make start-service
  <name>`, `make stop-service <name>`, or `make update-service <name>`.
- Before any restart or update, run `make -n <target> <service>` and read the
  output. Check whether the target can recreate dependencies because
  `start-service` uses `--force-recreate`.
- For n8n specifically, do not update or recreate without explicit approval and
  a verified backup and revert path.


## Timezone handling

Dave is in the `America/New_York` timezone (Eastern Time). Always interpret and display relative dates and times in `America/New_York` unless Dave explicitly says otherwise. Convert UTC, server, container, database, Grafana, and other local machine times to `America/New_York` before reporting them. Never assume UTC or Pacific/server-local time is Dave's timezone.

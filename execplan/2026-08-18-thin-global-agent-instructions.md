# Thin and layer global agent instructions

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. This repository does not contain a local `PLANS.md`; this plan follows the ExecPlan methodology loaded from the Hermes `execplan` skill.

## Purpose / Big Picture

Dave’s global Codex and Claude instruction files previously repeated policy, mixed global and project-specific procedures, and cost context in every session. The completed design keeps one small shared policy source, publishes deterministic runtime entrypoints for both clients, composes a thin Codex adapter, and leaves Claude with a thin adapter importing its stable user-level bridge. A fresh Git checkout plus the existing installer reproduces the same behavior on other machines. On Linux, existing symlinks make pulled changes live immediately. On Windows, rerunning the existing installer copies the updated entrypoints and shared bridge while preserving its current copy/junction model.

## Progress

- [x] (2026-08-18 20:57 EDT) Inspected the current global files, Linux and Windows installers, symlink chain, client subagent definitions, repository status, recent history, and current official instruction-loading documentation.
- [x] (2026-08-18 20:57 EDT) Chose a three-layer design that avoids unsupported Codex imports and uses Claude’s documented `@path` import support.
- [x] (2026-08-18 20:57 EDT) Added shared and client-specific source fragments plus a deterministic Codex renderer/checker.
- [x] (2026-08-18 21:07 EDT) Replaced the global Codex and Claude files with the rendered Codex entrypoint and thin Claude adapter.
- [x] (2026-08-18 21:07 EDT) Documented the architecture, added a changelog entry, and wired renderer verification into the versioned pre-commit hook.
- [x] (2026-08-18 21:07 EDT) Validated rendering, stale-output rejection, imports, installer references, content-size reduction, source-control scope, and fresh Codex/Claude behavior.
- [x] (2026-08-18 21:18 EDT) Completed independent review and corrected staged-snapshot validation, non-overridable safety boundaries, stable Claude import location, byte determinism, and stale plan text without touching unrelated work.

## Surprises & Discoveries

- Observation: Codex reads only one global `AGENTS.md` or `AGENTS.override.md` from `~/.codex`; it does not provide Claude-style Markdown imports.
  Evidence: OpenAI’s current AGENTS.md documentation says Codex uses only the first non-empty global file and then layers project files.
- Observation: Claude supports recursive `@path` imports in user-scope `CLAUDE.md`, including `~` paths, and loads them without the external-project approval dialog.
  Evidence: Anthropic’s current memory documentation explicitly recommends a `CLAUDE.md` importing `AGENTS.md` and permits user-scope imports.
- Observation: Linux uses live symlinks, but the Windows installer intentionally copies runtime instruction files while junctioning directories.
  Evidence: `install.conf.yaml` links `~/.codex/AGENTS.md` and all of `~/.claude`; `scripts/install-windows-config.ps1` copies the two adapters plus the generated shared-policy bridge.
- Observation: `scripts/dashboard-stop-hook.sh` was already modified before this task.
  Evidence: initial `git status --short` reported only that unrelated modification. This plan must not alter or stage it.

## Decision Log

- Decision: Store durable cross-client policy in `agent-instructions/shared.md`, Codex-only guidance in `agent-instructions/codex.md`, and Claude-only guidance directly in `claude/CLAUDE.md` after an import.
  Rationale: This gives one source of truth for shared policy while using each client’s actual loading capabilities.
  Date/Author: 2026-08-18 / Hermes
- Decision: Commit `codex/AGENTS.md` as generated output and add `scripts/render-agent-instructions.py --check`.
  Rationale: Codex cannot import the shared fragment. A committed deterministic composition updates on Git pull for Linux symlinks and remains reproducible for the Windows installer without runtime dependencies.
  Date/Author: 2026-08-18 / Hermes
- Decision: Keep the existing installer destinations unchanged.
  Rationale: Both clients continue reading the same live paths, so architecture changes remain internal to the repository and do not disrupt credentials, sessions, caches, or runtime state.
  Date/Author: 2026-08-18 / Hermes
- Decision: Preserve a concise OnRamp safety boundary globally but leave detailed commands and topology in `/apps/onramp/.agents/README.md`.
  Rationale: The high-risk boundary must survive cross-project work, while detailed project procedure belongs at the narrowest applicable scope.
  Date/Author: 2026-08-18 / Hermes
- Decision: Refer to configured worker roles instead of hard-coding current model version numbers.
  Rationale: Agent configuration already pins models; repeating versions in always-loaded prose creates immediate staleness when model routing changes.
  Date/Author: 2026-08-18 / Hermes

- Decision: Publish the shared policy to the stable runtime path `~/.claude/shared-agent-policy.md` as deterministic committed output.
  Rationale: Claude supports native imports, but an import of `~/.dotfiles/...` would break when the Windows installer runs from another clone location. Linux receives the bridge through the existing `~/.claude` symlink; Windows copies it beside `CLAUDE.md`.
  Date/Author: 2026-08-18 / Hermes
- Decision: Make pre-commit validation compare generated output to source blobs in Git’s index.
  Rationale: A working-tree-only check is incorrect for partially staged commits and can both accept stale staged output and reject valid staged snapshots.
  Date/Author: 2026-08-18 / Hermes

## Outcomes & Retrospective

Implementation and verification are complete. The result has one manually maintained shared policy, a deterministic Codex composition, a stable generated Claude import bridge, thin client adapters, index-aware drift protection, and unchanged live destinations for the two original entrypoints. The 324-line Claude file is now a 27-line adapter; a fresh Claude session loaded the generated bridge, Eastern Time, and non-overridable safety boundary successfully. The 72-line Codex file is now a 61-line generated entrypoint, and a fresh Codex session reported the expected timezone, worker, generated-file marker, and OnRamp boundary. Working-tree and temporary-index tests proved stale-output rejection and deterministic UTF-8/LF rendering. Concurrent dashboard-hook changes remained outside this task.

## Context and Orientation

The repository is `/home/dave/.dotfiles` on branch `production`. `codex/AGENTS.md` is the generated tracked entrypoint linked to `~/.codex/AGENTS.md` on Linux. `claude/CLAUDE.md` and the generated `claude/shared-agent-policy.md` live inside the tracked `claude/` directory, which is linked wholesale to `~/.claude` on Linux. The Windows script copies all three runtime files into the user profile and junctions larger directories. At baseline, the Codex file was 72 lines and the Claude file was 324 lines. Those files contained good rules but conflated shared behavior, client routing, OnRamp procedure, skills, connector mechanics, prose style catalogs, task-file conventions, and historical safeguards.

A “shared fragment” is manually maintained Markdown that is not discovered on its own. The renderer publishes it to Claude’s stable user-level import bridge and composes it with the Codex fragment in `codex/AGENTS.md`. A “client adapter” is a short client-specific section describing only routing and capabilities unique to that harness.

## Plan of Work

Create `agent-instructions/shared.md` with concise instructions for precedence, safety, evidence, scope, verification, writing, delegation, OpenBrain, timezone, and the OnRamp boundary. Preserve the behavior behind the strongest current rules without retaining their long exception catalogs.

Create `agent-instructions/codex.md` with explicit `cheap-worker` routing, active-root-model guidance, OpenSkills progressive disclosure, and no hard-coded root model version. Create `scripts/render-agent-instructions.py` to produce deterministic UTF-8/LF bytes for both generated outputs: the shared-plus-Codex entrypoint and Claude’s stable shared-policy bridge. The script supports default write mode, working-tree `--check`, and staged `--check-index`. The versioned pre-commit hook uses the index-aware mode so partially staged commits cannot bypass drift detection.

Replace `codex/AGENTS.md` with the renderer’s exact output. Replace `claude/CLAUDE.md` with a user-scope import of `@~/.claude/shared-agent-policy.md` plus a short adapter for the existing Explore, coder, architect, and reviewer routing; OpenSkills auto-routing; connected OpenBrain/connector behavior; and changelog maintenance. Update the Windows installer to copy the generated bridge beside `CLAUDE.md`. Do not enumerate pilot skills or repeat shared policy.

Update `README.md` to explain the source, generated output, Claude import, render/check command, Linux live-update behavior, and existing Windows installer behavior. Append a dated entry to `claude/CHANGELOG.md` describing the architecture and files.

## Concrete Steps

From `/home/dave/.dotfiles`, create the new source fragments and renderer, then run:

    python3 scripts/render-agent-instructions.py
    python3 scripts/render-agent-instructions.py --check

Expect the first command to write both `codex/AGENTS.md` and `claude/shared-agent-policy.md`; expect the second to print both as current and exit zero.

Validate Markdown paths and sizes with a small standard-library script. Resolve the Claude import as `~/.claude/shared-agent-policy.md` and confirm it is the generated bridge. Verify Linux links still resolve to the tracked files. Parse `install.conf.yaml` and inspect the Windows copy sources to ensure the original entrypoints remain and the bridge is copied beside `CLAUDE.md`.

Run repository checks that apply to documentation and scripts. At minimum:

    python3 -m py_compile scripts/render-agent-instructions.py
    python3 scripts/render-agent-instructions.py --check
    git diff --check

If the repository has a broader test command suitable for this change, run it only if it does not mutate unrelated state. Run a fresh Codex/Claude context check when their installed CLIs provide a bounded read-only way to report loaded instruction files.

## Validation and Acceptance

Acceptance requires all of the following observable behavior:

1. `agent-instructions/shared.md` is the only manually maintained copy of shared policy.
2. `python3 scripts/render-agent-instructions.py --check` exits zero, and `--check-index` compares generated files to staged source blobs rather than the working tree.
3. `codex/AGENTS.md` contains the shared policy and Codex adapter and is substantially smaller than the former combined policy burden.
4. `claude/CLAUDE.md` imports `~/.claude/shared-agent-policy.md` and contains only Claude-specific material; it is substantially smaller than 324 lines and 23 KB.
5. Existing Linux live paths resolve to the updated tracked entrypoints. The Windows installer retains the original destinations and additionally copies the generated shared-policy bridge.
6. The shared rules retain the high-signal intent: local precedence, secrets and destructive-Git safety, grounded facts, proportional root-cause fixes, verification before claims, plain prose/no AI attribution, progressive disclosure/delegation, OpenBrain use, Eastern Time, and the concise OnRamp boundary.
7. The pre-existing modification to `scripts/dashboard-stop-hook.sh` remains byte-for-byte outside this task’s diff.

## Idempotence and Recovery

The renderer is idempotent: rerunning it with unchanged fragments produces identical UTF-8/LF bytes. `--check` and `--check-index` never write. If generated output becomes stale, rerun the renderer. All edits are tracked text files; rollback is available through the file-scoped Git diff without touching unrelated dashboard-hook work. Do not use `git reset`, `git checkout --`, `git restore`, or `git clean`.

## Artifacts and Notes

Official client behavior used by this plan:

- Codex global discovery reads one file from `~/.codex`, then layers project files from root to current directory. There is no documented Markdown import syntax.
- Claude user-scope `CLAUDE.md` supports `@path` imports, resolves relative imports from the containing file, supports `~`, and recommends importing `AGENTS.md` when sharing policy across clients.

The initial repository status was:

    M scripts/dashboard-stop-hook.sh

That file is unrelated and must remain untouched.

## Interfaces and Dependencies

`scripts/render-agent-instructions.py` exposes this command-line interface:

    python3 scripts/render-agent-instructions.py [--check | --check-index]

With no option it writes `codex/AGENTS.md` and `claude/shared-agent-policy.md` as deterministic UTF-8/LF bytes. `--check` compares expected and actual working-tree bytes. `--check-index` renders from source blobs in Git’s index and compares them with staged generated blobs, which is the mode used by pre-commit. The script uses only the Python standard library and repository-relative constants, so it works from any current directory.

Revision note: 2026-08-18. Implementation and independent review are complete. Review findings covering staged-snapshot validation, safety precedence, explicit commit/push authorization, stable Claude import location, newline determinism, and stale plan text were corrected and revalidated.

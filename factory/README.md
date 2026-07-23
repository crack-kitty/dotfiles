# Dark Factory

Spec in, branch out. Drop a spec file in `specs/inbox/`, run
`scripts/factory-run`, review the outcome report in `specs/done/`, not the code.

## Flow

1. Write a spec from `specs/TEMPLATE.md` into `specs/inbox/`.
2. Run `scripts/factory-run`. It processes the oldest spec: clones the target
   repo into `work/<runid>/`, checks that the verify command currently fails,
   runs a headless claude build following the dark-factory skill, then runs the
   verify command again as an independent gate.
3. Verify pass: branch `factory/<runid>` is pushed to the source repo and a
   report lands in `specs/done/`. With `auto_merge: true` and a clean source
   tree, the branch is also fast-forward merged.
4. Verify fail: spec moves to `specs/failed/` with the build log path.

## Rules

- The verify command is the gate. If it cannot fail, the spec is rejected.
- One spec, one run, one branch. No spec edits mid-run.
- Reports get reviewed. Code gets reviewed only when a report smells wrong.

## Why scripts/ and not bin/

The damage-control hook blocks any Bash command containing `/bin/`, so a
`bin/` directory here would trip a false positive on every invocation.

## Not synced

This tree lives outside `~/.dotfiles` and is machine-local. The builder
protocol it depends on is the `dark-factory` skill, which does sync. If this
machine is rebuilt, recreate `scripts/factory-run` or move it into dotfiles.

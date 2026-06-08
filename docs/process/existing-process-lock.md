---
type: process
status: active
owner: engineering
created: 2026-05-21
updated: 2026-05-21
parent: "[[docs/process/README]]"
tags:
  - docs/process
  - status/active
aliases:
  - existing workflow
related:
  - "[[docs/architecture/existing-architecture-lock]]"
---

# Existing Process Lock

This document records the development workflow already used by the Compass
repository.

## Design Workflow

1. Restate the requested engineering change.
2. Run the Session Update Gate once per Codex session: compare the installed Compass skill with `https://github.com/wirnat/compass` and update the skill before continuing when it is stale. Prefer `npx skills update` for CLI-managed installs; otherwise use `scripts/update-skill.sh --skill-dir <installed-compass-skill-dir>`.
3. Check whether project docs are present and bootstrap them only after preset approval.
4. Read orientation, architecture, foundation, process, and relevant reference docs.
5. Classify the task by risk using `references/classification.xml`.
6. Load the task type from `references/task-types.xml`.
7. Load the active workflow from `docs/process/workflows.xml`.
8. Before implementation, run the Task Memory Gate. For approved gated design context, or for long/risky work with 2+ concrete slices, load `references/task-memory.xml`, create or resume task memory after goal alignment, and report `created`, `resumed`, or `not-required`.
9. Stop at approval gates before implementation.

Feature updates use delta-controlled checkpoints. Before editing, Compass must
identify the existing owner, baseline behavior, contracts that must remain
stable, and the risk level. Then it must define the exact old/new/unchanged
behavior delta, regression evidence, implementation slices, and any rollout,
rollback, compatibility, or cleanup controls.

## Implementation Workflow

Implementation must preserve the existing repository shape:

- Update `SKILL.md` for skill-facing policy.
- Update `references/*.xml` for structured reusable rules.
- Update `assets/docs-seed/` for docs every target project should receive.
- Update `assets/orientation-presets/<preset>/docs/` for preset-specific behavior.
- Update `scripts/bootstrap-docs.sh` for bootstrap mechanics.
- Update `docs/` for this repository's own context and decisions.

Work should proceed one approved slice at a time, with verification after each
slice.

Work with approved gated design context or long multi-slice risk must keep task memory current. Before the first implementation slice, create or resume `docs/.tasks/<task>/`; if task memory is not required, state why before editing. At each slice boundary, update `goal.md`, `diagram.md`, and `memories.md` before reporting the checkpoint.

Feature-update slices must preserve the approved baseline. Each slice reports
the delta implemented, regression evidence added or reused, verification result,
and remaining rollout or cleanup risk before continuing.

## Test And Verification Workflow

Use `docs/process/testing-strategy.md` as the testing source of truth. The
default test command remains intentionally lightweight and deterministic, and
slow headless agent tests should be opt-in only.

Use the closest available evidence:

- Run `./scripts/bootstrap-docs.sh --list-presets` after changing preset listing behavior.
- Run `./scripts/bootstrap-docs.sh --target <temp-dir> --preset <preset> --dry-run` after changing copy planning.
- Run `./scripts/bootstrap-docs.sh --target <temp-dir> --preset <preset>` after changing bootstrap output.
- Run `./scripts/smoke-test.sh` after changing bootstrap scripts or preset packaging.
- Run `./tests/run-tests.sh` before completing changes that affect docs policy, presets, workflows, scripts, or tests.
- Inspect generated docs for expected files and no unintended overwrite behavior when smoke-test coverage is insufficient.

## Commands

- Build command: none.
- Lint command: none.
- Test command: `./tests/run-tests.sh`.
- Bootstrap preset listing: `./scripts/bootstrap-docs.sh --list-presets`.
- Bootstrap dry run: `./scripts/bootstrap-docs.sh --target <project> --preset <preset> --dry-run`.
- Bootstrap execution: `./scripts/bootstrap-docs.sh --target <project> --preset <preset>`.
- Smoke test: `./scripts/smoke-test.sh`.
- Deterministic test wrapper: `./tests/run-tests.sh`.
- Skill CLI update: `npx skills update`.
- Skill update check: `./scripts/update-skill.sh --skill-dir <installed-compass-skill-dir> --check`.
- Skill update execution: `./scripts/update-skill.sh --skill-dir <installed-compass-skill-dir>`.
- Migration or codegen command: none.

## Review Checkpoint

Before a change is complete, report:

- task type and workflow source
- Session Update Gate result
- files changed
- docs updated or intentionally unchanged
- verification commands run
- any missing evidence or unresolved ambiguity

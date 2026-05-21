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
2. Check whether project docs are present and bootstrap them only after preset approval.
3. Read orientation, architecture, foundation, process, and relevant reference docs.
4. Classify the task by risk using `references/classification.xml`.
5. Load the task type from `references/task-types.xml`.
6. Load the active workflow from `docs/process/workflows.xml`.
7. Before implementation, run the Task Memory Gate. For long or risky work with 2+ concrete slices, load `references/task-memory.xml`, create or resume task memory after goal alignment, and report `created`, `resumed`, or `not-required`.
8. Stop at approval gates before implementation.

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

Long multi-slice work must keep task memory current. Before the first implementation slice, create or resume `docs/.tasks/<task>/`; if task memory is not required, state why before editing. At each slice boundary, update `goal.md`, `diagram.md`, and `memories.md` before reporting the checkpoint.

## Test And Verification Workflow

There is no dedicated test suite yet. Use the closest available evidence:

- Run `./scripts/bootstrap-docs.sh --list-presets` after changing preset listing behavior.
- Run `./scripts/bootstrap-docs.sh --target <temp-dir> --preset <preset> --dry-run` after changing copy planning.
- Run `./scripts/bootstrap-docs.sh --target <temp-dir> --preset <preset>` after changing bootstrap output.
- Inspect generated docs for expected files and no unintended overwrite behavior.

If future work adds a test runner, document the command here before relying on
it as completion evidence.

## Commands

- Build command: none.
- Lint command: none.
- Test command: no dedicated suite.
- Bootstrap preset listing: `./scripts/bootstrap-docs.sh --list-presets`.
- Bootstrap dry run: `./scripts/bootstrap-docs.sh --target <project> --preset <preset> --dry-run`.
- Bootstrap execution: `./scripts/bootstrap-docs.sh --target <project> --preset <preset>`.
- Migration or codegen command: none.

## Review Checkpoint

Before a change is complete, report:

- task type and workflow source
- files changed
- docs updated or intentionally unchanged
- verification commands run
- any missing evidence or unresolved ambiguity

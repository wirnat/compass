---
type: decision
status: active
owner: architecture
created: 2026-05-21
updated: 2026-05-21
parent: "[[docs/decisions/README]]"
tags:
  - docs/decisions
  - status/active
aliases:
  - orientation lock
related:
  - "[[docs/architecture/existing-architecture-lock]]"
  - "[[docs/foundation/existing-principles-lock]]"
  - "[[docs/process/existing-process-lock]]"
---

# 0001 Orientation Lock

## Decision

Compass locks this project to the `existing-architecture-lock` preset.

The repository is already organized as an installable Codex skill with a stable
entrypoint, reference files, seed documentation assets, orientation presets, and
one bootstrap script. Future work must extend that shape unless an explicit
architecture decision changes it.

## Rationale

- `SKILL.md` is the policy entrypoint for Compass behavior.
- `references/` owns machine-readable routing, task taxonomy, bootstrap, and documentation policy rules.
- `assets/docs-seed/` owns generic project documentation seed files.
- `assets/orientation-presets/<preset>/docs/` owns preset-specific documentation and workflow material.
- `scripts/bootstrap-docs.sh` owns idempotent docs bootstrap behavior.
- `agents/openai.yaml` owns the OpenAI plugin metadata.

This shape is small, explicit, and already documented in the public README. A new
architecture would add ceremony without solving the current problem.

## Evidence To Record

- Existing folders and boundaries: `SKILL.md`, `README.md`, `references/`, `assets/`, `scripts/`, `agents/`, and now `docs/`.
- Existing principles: documentation-first workflow, project-owned `docs/` context, explicit gates, idempotent bootstrap, and preset adaptation before use.
- Existing development workflow: classify by risk, load project docs, follow `docs/process/workflows.xml`, update docs when boundaries or workflows change, and implement only approved slices.
- Commands verified: `./scripts/bootstrap-docs.sh --target . --preset existing-architecture-lock`.
- Build/test status: no package manager, language runtime, or automated test suite is currently present; shell-script verification is the available project command.

## Consequences

- New Compass behavior should usually update `SKILL.md`, `references/*.xml`, `assets/docs-seed/`, `assets/orientation-presets/`, or `scripts/bootstrap-docs.sh` rather than introducing new top-level architecture folders.
- Durable project memory must live under target project `docs/` because Compass already treats that directory as the automatic context pack.
- Any competing workflow source must be rejected unless a new decision record supersedes this lock.

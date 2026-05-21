---
type: foundation
status: active
owner: architecture
created: 2026-05-21
updated: 2026-05-21
parent: "[[docs/foundation/README]]"
tags:
  - docs/foundation
  - status/active
aliases:
  - existing principles
related:
  - "[[docs/architecture/existing-architecture-lock]]"
---

# Existing Principles Lock

This document records the principles already implied by the Compass repository.

## Principles

1. Project docs are the context pack.

   Compass must read and update the target project's `docs/` directory instead
   of depending on `AGENTS.md` links for project knowledge.

2. Workflow source must be singular.

   `docs/process/workflows.xml` is the active workflow source inside a target
   project. Root-skill references and preset files can seed or explain behavior,
   but they must not compete with the project-owned workflow.

3. Bootstrap is explicit and idempotent.

   Compass offers presets, waits for selection, copies missing files, and avoids
   overwriting existing docs unless `--force` is requested.

4. Presets are references, not blind boilerplate.

   Copied docs must be adapted to the target language, framework, and repository
   conventions before they are treated as ready.

5. Risk controls workflow.

   Compass classifies by engineering risk, then follows the matching workflow and
   approval gates. A user's label does not override the risk.

6. Implementation happens by approved slices.

   Large work is split into small checkpoints. Each implementation slice needs
   verification before the next slice starts.

## Trade-offs

- Compass accepts more upfront documentation to reduce long-term context loss.
- Strict gates slow the first response, but they reduce silent architecture drift.
- XML references are verbose for humans, but they make workflow rules explicit and structured for agents.
- A single shell script keeps bootstrap portable, but limits richer validation until a test strategy is added.

## Anti-patterns To Avoid

- Treating `README.md` as the only source of truth for workflow behavior.
- Adding project memory outside `docs/`.
- Copying preset docs without adapting them.
- Creating new root folders to express an idea that already has a home in the existing architecture.
- Skipping approval gates because the requested change looks small.

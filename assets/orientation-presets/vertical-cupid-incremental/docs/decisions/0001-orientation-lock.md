---
type: decision
status: active
owner: architecture
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/decisions/README]]"
tags:
  - docs/decisions
  - status/active
aliases:
  - orientation lock
related:
  - "[[docs/architecture/vertical-slice-architecture]]"
  - "[[docs/architecture/feature-slice-structure]]"
  - "[[docs/foundation/cupid-yagni-principles]]"
  - "[[docs/process/incremental-test-workflow]]"
---

# 0001 Orientation Lock

## Decision

Compass locks this project to the `vertical-cupid-incremental` preset.

## Architecture

Use [[docs/architecture/vertical-slice-architecture]].
Use [[docs/architecture/feature-slice-structure]] for folder and file placement.

## Principles

Use [[docs/foundation/cupid-yagni-principles]].

## Development Workflow

Use [[docs/process/incremental-test-workflow]].

## Consequences

- Feature work is organized by request, command, query, or workflow.
- Folder structure follows feature slices before technical layers.
- Shared abstractions require real callers.
- Tests stay close to the behavior slice.

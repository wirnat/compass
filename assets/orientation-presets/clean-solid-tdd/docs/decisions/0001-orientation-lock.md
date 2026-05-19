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
  - compass lock
related:
  - "[[docs/architecture/clean-architecture]]"
  - "[[docs/architecture/folder-file-structure]]"
  - "[[docs/foundation/solid-principles]]"
  - "[[docs/process/tdd-workflow]]"
---

# 0001 Orientation Lock

## Decision

Compass locks this project to the `clean-solid-tdd` preset.

## Architecture

Use [[docs/architecture/clean-architecture]].

Use [[docs/architecture/folder-file-structure]] as the concrete folder and file map.

## Principles

Use [[docs/foundation/solid-principles]].

## Development Workflow

Use [[docs/process/tdd-workflow]].

## Consequences

- Feature design starts from usecase contracts and domain behavior.
- Dependencies point inward.
- Folder growth follows the documented module and platform structure.
- Adapters are added only when boundary behavior needs evidence.
- TDD is the default implementation mechanism for testable behavior.
- New root folders, competing layer names, dependency containers, and shared helper drawers require explicit architecture approval.

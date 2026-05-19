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
  - "[[docs/architecture/domain-driven-design]]"
  - "[[docs/architecture/bounded-context-structure]]"
  - "[[docs/foundation/domain-modeling-principles]]"
  - "[[docs/process/bdd-tdd-workflow]]"
---

# 0001 Orientation Lock

## Decision

Compass locks this project to the `ddd-solid-bdd` preset.

## Architecture

Use [[docs/architecture/domain-driven-design]].
Use [[docs/architecture/bounded-context-structure]] for folder and file placement.

## Principles

Use [[docs/foundation/domain-modeling-principles]].

## Development Workflow

Use [[docs/process/bdd-tdd-workflow]].

## Consequences

- Domain language drives code and test names.
- Bounded contexts and integration contracts are explicit.
- Folder structure follows bounded context ownership before technical layers.
- Behavior examples are clarified before implementation.

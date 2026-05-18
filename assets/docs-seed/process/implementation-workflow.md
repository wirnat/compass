---
type: process
status: active
owner: engineering
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/process/README]]"
tags:
  - docs/process
  - status/active
aliases:
  - implementation workflow
related:
  - "[[docs/foundation/engineering-philosophy]]"
  - "[[docs/foundation/architecture-principles]]"
  - "[[docs/foundation/testing-principles]]"
---

# Implementation Workflow

This document defines how implementation work proceeds after the target behavior and boundary are clear enough to start coding.

## Principles

- Start from the cheapest meaningful evidence.
- Create folders lazily when there is real behavior, a real contract, or a real implementation.
- Grow inside the established project structure unless the task is explicitly an architecture change.
- Keep core behavior testable without delivery, persistence, framework, or external service dependencies.
- Add adapters only after the core behavior and application contracts are clear.
- Do not create abstractions before a caller needs them.

## Architecture Change Gate

Changes that alter architecture boundaries must update documentation before or together with code. This includes new folder or layer categories, changed dependency direction, changed composition style, new cross-boundary contract patterns, or new shared technical capability categories.

## Default Workflow

1. Define the target behavior in plain terms.
2. Choose the cheapest test level that proves the behavior.
3. Add a failing core test when the behavior is a pure invariant, policy, or value rule.
4. Add a failing application test when the behavior coordinates rules, branching, persistence contracts, time, IDs, or external capabilities.
5. Define narrow contracts only when the application behavior needs an outside capability.
6. Implement the minimum core and application code needed to make the test pass.
7. Add delivery adapters only when request parsing, response mapping, status mapping, route registration, or command mapping need evidence.
8. Add persistence adapters only when persistence mapping, query behavior, schema assumptions, or transaction behavior need evidence.
9. Wire the behavior through the project's existing composition root after the implementation and required adapters exist.

## Test Placement

Use core tests for pure business rules, invariants, value objects, and policies.

Use application tests for orchestration, branching, consumer-side contracts, fake repositories, fake clocks, fake ID generators, and application-specific behavior.

Use adapter tests for boundary translation, request parsing, response mapping, persistence mapping, external service payload mapping, and status or error behavior.

Use integration tests for real infrastructure assumptions.

Use end-to-end tests only when the behavior needs cross-layer evidence that cannot be proven cheaply at a lower level.

## Avoid

- proving core behavior through heavy boundary tests when lower-level tests provide the same confidence
- creating all folders before behavior exists
- creating alternate layer folders without architecture approval
- defining provider-owned interfaces that consumers do not need
- letting outside request, response, or persistence shapes leak into core behavior
- building generic helpers to support only one caller

## Completion Evidence

- The first test failed for the expected reason before implementation when practical.
- The final test command for the touched scope passed.
- New folders contain real behavior, contracts, or implementations.
- New folders stay inside the established structure, or the architecture change was explicitly requested and documented.
- Core behavior does not import delivery, persistence, framework, or runtime infrastructure.
- Composition stays near the project's existing composition root.

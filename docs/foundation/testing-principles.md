---
type: foundation
status: active
owner: engineering
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/foundation/README]]"
tags:
  - docs/foundation
  - status/active
aliases:
  - testing principles
related:
  - "[[docs/foundation/engineering-philosophy]]"
  - "[[docs/process/implementation-workflow]]"
---

# Testing Principles

Testing is a design and verification tool. Tests should clarify behavior, protect contracts, and make change safer without forcing unnecessary architecture.

## Main Rule

Choose the cheapest test level that still proves the behavior.

## Test Levels

- Core tests prove pure rules, invariants, values, and policies without infrastructure.
- Application tests prove orchestration, branching, consumer-side contracts, fake repositories, fake clocks, fake ID generators, and scenario behavior.
- Adapter tests prove request parsing, response mapping, persistence mapping, external payload mapping, and boundary errors.
- Integration tests prove real infrastructure assumptions when fakes are not enough.
- End-to-end tests prove important cross-layer flows that cannot be trusted through lower-level evidence alone.

## Local Verification

Integration and end-to-end tests run on the developer's machine, next to every other project there. Keep them repeatable and cheap:

- Run them against the local environment described in `docs/process/local-environment.md`, never against remote databases or shared staging services unless the developer approves.
- Isolate each run's data with its own database, schema, or key prefix, or clean up afterwards, so parallel runs and other projects are not affected.
- Start only the dependencies the tests need, and reuse shared local services when they already run.
- Write down the command that starts the environment and the command that runs the tests.

## TDD Use

Use TDD when behavior is being added or changed:

1. Write the smallest test that expresses the target behavior.
2. Run it and confirm it fails for the expected reason.
3. Implement the minimum code that makes it pass.
4. Refactor after the behavior is proven.

TDD is not a moral ritual. It is a feedback loop.

## Avoid

- testing private implementation details without contract value
- using mocks to force unnecessary indirection
- proving pure behavior only through heavy integration tests
- keeping brittle tests that fail during behavior-preserving refactors
- treating coverage percentage as stronger evidence than meaningful scenarios

## Completion Evidence

Before claiming work is complete, state:

- which behavior was protected
- which command was run
- whether the test failed first when that matters
- what verification could not be run and why
- which local environment integration or end-to-end tests ran against, when they were used

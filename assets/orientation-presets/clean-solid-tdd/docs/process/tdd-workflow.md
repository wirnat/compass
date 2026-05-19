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
  - TDD
  - red green refactor
  - module implementation workflow
related:
  - "[[docs/architecture/clean-architecture]]"
  - "[[docs/architecture/folder-file-structure]]"
  - "[[docs/foundation/solid-principles]]"
---

# TDD Workflow

This project uses TDD as the default implementation mechanism when behavior can be tested before implementation.

TDD is not theater. The test is not a ceremonial candle. The test is evidence that the behavior was understood before code tried to be clever.

## Core Cycle

1. Red: write the smallest failing test for the selected behavior.
2. Green: implement the smallest code that makes the test pass.
3. Refactor: improve names, shape, duplication, and boundaries while tests stay green.

## Work Sequence For A Feature Slice

1. Define the target behavior in plain terms.
2. Choose the cheapest test level that proves the behavior.
3. Add a failing `domain` test when the behavior is a pure invariant, policy, calculation, or value rule.
4. Add a failing `usecase` test when the behavior coordinates domain rules, branching, persistence contracts, time, IDs, or external capabilities.
5. Define narrow ports only when the usecase needs an outside capability.
6. Implement the minimum `domain` and `usecase` code needed to pass the test.
7. Add `adapters/http` only when request parsing, response mapping, status codes, or route registration need evidence.
8. Add `adapters/postgres` only when persistence mapping, query behavior, transaction behavior, or schema assumptions need evidence.
9. Wire the module in `module.go` after usecase and required adapters exist.
10. Register module routes through the application route composition contract only after HTTP routes exist.

## Test Placement

| Behavior | Preferred test level | Example |
| --- | --- | --- |
| pure calculation or invariant | domain test | money calculation, discount rule, quantity validation |
| application orchestration | usecase test | checkout flow, registration flow, workflow branching |
| consumer-side contract | usecase test with fake port | repository, clock, ID generator, external reader |
| HTTP parsing and response mapping | adapter test | invalid JSON, status code, response body |
| persistence mapping | adapter or integration test | row-to-domain mapping, transaction behavior |
| real infrastructure assumption | integration test | SQL constraint, migration, external service sandbox |
| full user path | end-to-end test | only when lower levels cannot prove the risk |

## Folder Creation Gate

Before creating a folder during implementation, classify it:

- `implementation growth`: the folder fits [[docs/architecture/folder-file-structure]] and contains real behavior, a real contract, or a real implementation.
- `framework change`: the folder introduces a new root area, new `internal/` peer area, new layer name, or competing architecture pattern.

Proceed with implementation growth. Stop on framework change unless the user explicitly requested an architecture change and docs are updated.

Examples of implementation growth:

- `internal/modules/transaction/domain` for real transaction rules
- `internal/modules/transaction/usecase/checkout` for a checkout operation with local DTOs, ports, and tests
- `internal/modules/transaction/adapters/http` after HTTP behavior is selected
- `internal/platform/clock` when multiple modules need a shared clock implementation

Examples of framework change:

- adding `internal/services`
- adding `internal/repositories`
- adding root-level `pkg` for convenience
- adding a dependency injection container
- creating `common` or `utils` as a shared drawer

## TDD By Layer

### Domain First

Use domain tests when the behavior is pure:

- value validation
- calculations
- state transitions
- policy decisions
- domain errors

Domain tests must not need HTTP, database, framework, queue, file system, or external services.

### Usecase Second

Use usecase tests when behavior coordinates steps:

- calls to repositories or readers
- time or ID generation
- branching based on domain results
- transaction-like application flow
- business error mapping at application level

Use small fakes for ports. Fakes must preserve the same contract as production adapters.

### Adapters After Contracts

Add adapters after the usecase contract is clear.

HTTP adapters prove:

- request parsing
- transport validation
- response mapping
- status code mapping
- route registration

Persistence adapters prove:

- schema assumptions
- query behavior
- transaction behavior
- row/model mapping
- database error translation

Do not use adapters to discover domain rules. That is like asking the school gate to teach algebra.

## Cross-Module Rules

For read-only projections that need data from another module's table, keep the query in the consumer module's persistence adapter and make the schema dependency explicit in tests or migration evidence.

If a usecase needs another module's rule or invariant, stop and define a clear contract for that decision or reconsider the module boundary. Do not encode that rule as an incidental SQL lookup.

## Exceptions

If writing a test first is not practical:

1. State why test-first is not practical.
2. Keep the implementation slice smaller than usual.
3. Add the cheapest verification before claiming completion.
4. Add regression coverage as soon as the behavior shape is clear.

Skipping test-first is a documented exception, not a new lifestyle.

## Completion Evidence

Compass must report:

- the first failing test and expected failure when practical
- final test command and result
- files changed
- new folders and why they fit the documented structure
- whether domain/usecase stayed free from adapters and platform implementations
- any verification not run and why
- remaining risks

## Avoid

- Proving core business behavior through HTTP or database tests when domain or usecase tests provide the same confidence.
- Creating all module folders before behavior exists.
- Creating alternate layer folders such as `delivery`, `repository`, `service`, `handler`, `common`, or `utils`.
- Defining repository interfaces in Postgres adapters.
- Letting HTTP request or database model shapes leak into domain or usecase.
- Importing another module's internal source code for a core usecase flow.
- Duplicating another module's rule or invariant through SQL.
- Hiding cross-table read projections as ordinary single-module persistence.
- Adding a dependency injection container before manual wiring has proven maintenance friction.
- Building generic helpers to support only one caller.

## External References

- Kent Beck, "Test Driven Development: By Example"
- Martin Fowler, "Test-Driven Development": https://martinfowler.com/bliki/TestDrivenDevelopment.html
- Red, Green, Refactor overview: https://www.codecademy.com/article/tdd-red-green-refactor

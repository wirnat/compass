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
  - BDD
  - TDD
  - behavior workflow
related:
  - "[[docs/architecture/domain-driven-design]]"
  - "[[docs/architecture/bounded-context-structure]]"
  - "[[docs/foundation/domain-modeling-principles]]"
---

# BDD And TDD Workflow

This project uses BDD to clarify domain meaning, then TDD to implement selected behavior.

BDD asks: what behavior matters to the business?

TDD asks: what is the smallest executable evidence that this behavior works?

Together they stop the team from building a technically correct answer to the wrong business question. That is like getting full marks in math while answering the science exam.

## Workflow

1. Identify the bounded context affected by the request.
2. Write behavior scenarios in domain language.
3. Mark scenarios as selected, rejected, or postponed.
4. Identify affected domain concepts: aggregate, value object, domain service, event, or application usecase.
5. Choose the cheapest test level for each selected scenario.
6. Run red-green-refactor for testable domain or application behavior.
7. Add adapter tests only when translation behavior matters.
8. Add integration tests for context boundaries, persistence assumptions, and external contracts.
9. Update context README or context map when ownership or integration changes.

## Scenario Shape

Use Given/When/Then when it improves clarity:

```text
Scenario: Booking is confirmed when payment is accepted
Given a pending booking
And the customer has paid the required amount
When the booking is confirmed
Then the booking becomes confirmed
And a BookingConfirmed event is recorded
```

Guidance:

- Given describes relevant domain state.
- When describes the business event or user action.
- Then describes observable business outcome.
- Avoid framework words in scenarios.
- Avoid database table names in scenarios.
- Use business language even when tests are technical.

## Scenario Selection

Before implementation, classify scenarios:

- `selected`: must be implemented now
- `postponed`: valid behavior, not part of this slice
- `rejected`: intentionally out of scope or not a desired rule

Do not implement postponed behavior. Do not leave behavior ambiguous.

## Test Level Selection

| Scenario type | Preferred test level |
| --- | --- |
| value validation or calculation | domain test |
| aggregate invariant | domain test |
| usecase orchestration | application/usecase test |
| context contract | contract or integration test |
| HTTP request/response mapping | adapter test |
| persistence mapping or transaction | adapter/integration test |
| cross-context workflow | contract plus focused integration test |

## Red-Green-Refactor

For selected behavior:

1. Red: write the failing test or executable scenario.
2. Green: implement the smallest domain/application code.
3. Refactor: improve language, boundaries, and duplication.

Refactor must preserve the ubiquitous language. Do not rename business concepts into vague technical names because the IDE autocomplete looked tidy.

## Context Boundary Gate

Stop and update architecture docs when:

- a new bounded context is created
- a concept changes ownership
- one context needs another context's rule
- a shared kernel concept is proposed
- an anti-corruption layer is needed
- an event or contract crosses context boundaries

## Adapter Gate

Add adapters after behavior and contracts are clear.

HTTP adapter evidence:

- request parsing
- response mapping
- status code mapping
- scenario-to-error mapping

Persistence adapter evidence:

- aggregate persistence mapping
- optimistic/concurrency assumptions
- transaction boundary
- schema contract

Event adapter evidence:

- event serialization
- publish behavior
- subscriber contract
- idempotency or retry behavior when relevant

## Completion Evidence

Compass must report:

- selected behavior scenarios
- rejected and postponed scenarios
- context owner
- domain concept changed
- first failing test when practical
- final verification command and result
- context map or README update when ownership/integration changed
- remaining ambiguity or business questions

## Avoid

- Implementing behavior that has not been selected.
- Hiding domain ambiguity behind technical names.
- Creating aggregates before invariants exist.
- Using end-to-end tests when domain or usecase tests prove the same rule.
- Calling every behavior a service.
- Sharing raw domain models across contexts.
- Letting database schema become the ubiquitous language.

## External References

- Dan North, "Introducing BDD": https://dannorth.net/blog/introducing-bdd/
- Martin Fowler, "Bounded Context": https://martinfowler.com/bliki/BoundedContext.html
- Eric Evans, "Domain-Driven Design: Tackling Complexity in the Heart of Software"

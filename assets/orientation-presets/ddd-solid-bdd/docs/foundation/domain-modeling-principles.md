---
type: foundation
status: active
owner: architecture
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/foundation/README]]"
tags:
  - docs/foundation
  - status/active
aliases:
  - domain modeling
  - ubiquitous language
related:
  - "[[docs/architecture/domain-driven-design]]"
  - "[[docs/architecture/bounded-context-structure]]"
  - "[[docs/process/bdd-tdd-workflow]]"
---

# Domain Modeling Principles

Domain modeling turns business language into executable software boundaries.

The project should not merely store business data. It should express business meaning. A database row can remember numbers; the domain model should remember why the numbers matter.

## Principles

1. Use business language in code, docs, tests, and conversations.
2. Keep each concept owned by one bounded context.
3. Make rules explicit where they belong.
4. Model values and invariants before technical storage.
5. Prefer small contracts between contexts over shared mutable models.
6. Let domain complexity earn tactical patterns.
7. Use behavior examples to expose ambiguity.
8. Keep technical detail outside the domain model.

## Ubiquitous Language Discipline

Every important term should have one clear meaning inside a bounded context.

Compass should ask for clarification when:

- the same term appears with different meanings
- business language and code language differ
- a new concept has only a technical name
- a behavior cannot be described without vague words like "process", "handle", or "manage"

## Aggregate Discipline

Aggregates are consistency boundaries, not folder decorations.

Use an aggregate when:

- invariants must be protected together
- state changes must be coordinated
- callers need a controlled entry point
- transactional consistency matters

Avoid an aggregate when:

- the object is only read as a projection
- there are no invariants
- it would become huge and slow
- the boundary exists only because a diagram needed a box

## Value Object Discipline

Value objects should carry meaning and invariants.

Good value object candidates:

- Money
- Quantity
- Email
- DateRange
- Discount
- SerialNumber
- ProductCode

Weak value object candidates:

- a wrapper around `string` with no rule
- a wrapper around `int` with no invariant
- a type created only to satisfy architecture ceremony

## Domain Event Discipline

Domain events describe facts that happened in the business.

Good:

- `OrderPaid`
- `BookingConfirmed`
- `StockReserved`

Weak:

- `DataUpdated`
- `ProcessCompleted`
- `ThingChanged`

If the event name does not teach the business fact, improve the model.

## SOLID Use In DDD

SOLID applies inside DDD boundaries:

- SRP: one domain concept has one primary reason to change
- OCP: add new policies or usecases when real variation appears
- LSP: adapters and fakes preserve application contract meaning
- ISP: ports stay narrow and consumer-owned
- DIP: domain and application do not depend on technical implementations

Do not use SOLID to hide poor domain language behind abstractions.

## Review Checklist

- Can a domain expert recognize the names?
- Does each context have a clear language boundary?
- Is a rule duplicated across contexts?
- Does each aggregate protect a real invariant?
- Does each value object enforce meaningful rules?
- Are domain events named as business facts?
- Is technical storage shaping the model too early?
- Is the model simpler than the business reality, or more complex than it needs to be?

## Anti-Patterns

- Anemic domain model: all data, no behavior.
- Everything service: `OrderService`, `PaymentService`, `CustomerService`, all doing mixed work.
- One aggregate to rule the whole domain.
- Shared domain models across contexts.
- Database-first modeling for business rules.
- Domain events named after technical operations.
- Ubiquitous language documented once and ignored in code.

## External References

- Eric Evans, "Domain-Driven Design: Tackling Complexity in the Heart of Software"
- Martin Fowler, "Bounded Context": https://martinfowler.com/bliki/BoundedContext.html
- Martin Fowler, "Anemic Domain Model": https://martinfowler.com/bliki/AnemicDomainModel.html

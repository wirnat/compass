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
  - SOLID
  - solid principles
  - clean architecture principles
related:
  - "[[docs/architecture/clean-architecture]]"
  - "[[docs/architecture/folder-file-structure]]"
  - "[[docs/process/tdd-workflow]]"
---

# SOLID Principles

SOLID is used as a practical design compass. It keeps Clean Architecture alive at module, package, file, struct, function, and interface level.

The point is not to recite five letters. The point is to keep code easy to change without one tiny feature shaking the whole house like a child slamming the classroom door.

## Summary

| Principle | Daily question | Compass answer |
| --- | --- | --- |
| Single Responsibility | Why should this unit change? | One unit should have one primary reason to change. |
| Open/Closed | Can behavior grow without rewriting stable code? | Extend through focused policies, ports, or adapters when real variation exists. |
| Liskov Substitution | Can this implementation replace another safely? | Implementations must preserve the consumer contract. |
| Interface Segregation | Does the consumer need all these methods? | Prefer small consumer-side ports. |
| Dependency Inversion | Who owns the dependency shape? | Inner policy owns the contract; outer detail implements it. |

## Single Responsibility Principle

One module, package, file, struct, or function should have one primary reason to change.

Good signs:

- a domain file changes when business rules change
- a usecase file changes when application flow changes
- an HTTP request file changes when transport input changes
- a mapper changes when persistence or transport shape changes

Bad signs:

- one handler validates business rules, writes SQL, and formats HTTP responses
- one `service` package contains every operation
- one `helper` package knows about money, dates, requests, and database rows
- one file changes for business rules, route wiring, and persistence mapping

Compass rule: if a file has several unrelated reasons to change, split by responsibility before adding more behavior.

## Open/Closed Principle

Stable behavior should be extendable without frequent rewrites.

In this project, extension usually happens through:

- a new usecase operation when the user goal is different
- a new domain policy when a real business variation appears
- a new adapter when the technical implementation changes
- a new small port when a usecase needs an outside capability

OCP is not an excuse to create abstractions early. Do not create a policy, strategy, factory, or interface just because variation might happen someday. Someday is not a requirement; it is a weather forecast.

Compass rule: add extension points only after there is a real caller, variation, test, or approved design reason.

## Liskov Substitution Principle

An implementation of a contract must replace another implementation without breaking consumer expectations.

Examples:

- a memory repository and Postgres repository must return the same business meaning for not found, duplicate, and validation-related outcomes
- a fake clock must preserve the same time semantics expected by the usecase
- an external service adapter must not silently convert provider failure into business success
- a test fake must behave according to the same port contract, not according to what makes the test easy

Compass rule: every port should document the meaning of its outputs and errors well enough that fakes and production adapters can be substituted safely.

## Interface Segregation Principle

Consumers should not depend on methods they do not use.

Good:

```go
type ProductPriceReader interface {
	ReadPrice(ctx context.Context, productID string) (PriceSnapshot, error)
}
```

Risky:

```go
type ProductRepository interface {
	Create(...)
	Update(...)
	Delete(...)
	Find(...)
	List(...)
	Search(...)
	Sync(...)
}
```

The first contract says exactly what the usecase needs. The second contract invites every future operation to depend on a kitchen sink.

Compass rule: interfaces are created on the consumer side and should be as small as the usecase can honestly use.

## Dependency Inversion Principle

High-level policy does not depend on low-level detail. They meet through abstractions controlled by the inner layer.

In this project:

- domain owns pure rules
- usecase owns application flow and ports
- adapters implement ports
- composition connects ports to adapters

Correct direction:

```text
usecase defines ProductPriceReader
adapters/postgres implements ProductPriceReader
module.go wires postgres adapter into usecase
```

Wrong direction:

```text
usecase imports postgres.Repository
domain imports gorm.Model
handler directly calls SQL and builds business decisions
```

Compass rule: when inner behavior needs outer capability, define the smallest inner contract. Do not import the outer detail inward.

## Relationship To Clean Architecture

Clean Architecture protects large boundaries. SOLID protects the smaller code units inside those boundaries.

- SRP keeps files and packages from becoming mixed-purpose drawers.
- OCP helps behavior grow through deliberate extension points.
- LSP keeps adapters and fakes honest.
- ISP keeps ports small and consumer-owned.
- DIP keeps dependency direction inward.

If SOLID and folder structure conflict, prefer the responsibility and dependency principle, then update the folder structure doc so the map matches the land.

## Practical Boundary Rules

1. If code contains pure business rules, place it in domain.
2. If code coordinates an application goal, place it in usecase.
3. If code translates outside formats, place it in an adapter.
4. If code prepares shared technical tools, place it in platform.
5. If inner behavior needs outer capability, define a small port in the inner layer.
6. If data crosses a boundary, use a struct owned by the receiving boundary.
7. If a package starts to get a generic name, find clearer ownership.
8. If a test needs a database to prove a pure rule, inspect the boundary.
9. If a module needs another module's table for read-only projection, keep the query in the consumer persistence adapter.
10. If a module needs another module's rule, use a contract or change the boundary.

## Review Checklist

- Does this unit have one primary reason to change?
- Did we add an abstraction because there is a real need?
- Can every adapter or fake preserve the same port contract?
- Is each interface owned by the consumer that needs it?
- Do domain and usecase avoid concrete technical detail?
- Did we avoid generic package names like `common`, `helper`, and `utils`?
- Is each test proving behavior at the cheapest meaningful level?

## Anti-Patterns

- Making one huge service because it feels simpler today.
- Creating interfaces beside providers instead of consumers.
- Creating broad repositories with unused methods.
- Hiding provider failures behind business success.
- Using fakes that behave differently from production adapters.
- Adding abstractions before the second real use case exists.
- Treating SOLID as an excuse for too many tiny files with no clearer boundary.

## External References

- Robert C. Martin, "The Single Responsibility Principle": https://blog.cleancoder.com/uncle-bob/2014/05/08/SingleReponsibilityPrinciple.html
- Robert C. Martin, "The Clean Architecture": https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- SOLID overview: https://en.wikipedia.org/wiki/SOLID

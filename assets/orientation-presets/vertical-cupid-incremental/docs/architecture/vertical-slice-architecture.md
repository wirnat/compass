---
type: architecture
status: active
owner: architecture
created: 2026-05-19
updated: 2026-05-19
parent: "[[docs/architecture/README]]"
tags:
  - docs/architecture
  - status/active
aliases:
  - vertical slice
  - vertical slice architecture
  - feature slice
related:
  - "[[docs/architecture/feature-slice-structure]]"
  - "[[docs/foundation/cupid-yagni-principles]]"
  - "[[docs/process/incremental-test-workflow]]"
  - "[[docs/decisions/0001-orientation-lock]]"
---

# Vertical Slice Architecture

This project uses Vertical Slice Architecture when feature-local change is more valuable than shared layering.

The purpose is not to remove architecture. The purpose is to put architecture on the axis where the code actually changes: user-visible behavior, request, command, query, or workflow.

## Research Basis

Jimmy Bogard describes Vertical Slice Architecture as building around distinct requests and grouping concerns from front end to back. The important rule is to maximize coupling inside a slice and minimize coupling between slices.

That idea matters because many day-to-day changes do not touch one technical layer only. A feature often touches input, validation, business decision, persistence query, mapping, response shape, and tests. Vertical Slice Architecture lets those things live close together when they change together.

## Core Rule

Organize behavior around a slice, not around generic technical layers.

A slice may be:

- A command: `CreateInvoice`, `ApproveRefund`, `CancelBooking`
- A query: `GetInvoiceDetail`, `ListAvailableRooms`, `SearchCustomers`
- A workflow step: `VerifyPayment`, `SendReminder`, `RecalculateSchedule`
- A public endpoint or message handler when that endpoint/message is the natural unit of change

Keep coupling high inside the slice and low between slices. Anak SD version: teman sebangku boleh bisik-bisik, tapi jangan satu kelas jadi rantai gosip.

## What Belongs Inside A Slice

A slice can own everything needed to deliver one behavior:

- Request, command, or query model
- Input validation
- Handler or use-case function
- Local business rules
- Local persistence query or repository implementation
- Response/result model
- Event emission for the behavior
- Tests for the behavior

The slice is allowed to be pragmatic. A simple read query does not need the same shape as a complex command. If the behavior is simple, the slice should be simple.

## What Does Not Belong Inside A Slice

Do not put unrelated behavior in a slice just because the feature name sounds similar.

Avoid:

- Shared helpers that are only used by one slice
- Generic `service` classes that become a second application layer
- Repositories created only because "every feature must have a repository"
- Cross-slice imports for business decisions
- One slice directly mutating another slice's data model without an explicit contract

If two slices need the same behavior, duplicate it briefly until the real shared concept is visible. Duplication is not automatically sin; premature abstraction is often sin wearing a tie.

## Slice Boundary Rules

Use these rules before creating or moving code:

- One user-visible behavior should be findable in one slice folder.
- A slice should not require reading unrelated slices to understand its happy path.
- Shared code must have at least two real callers or a stable platform reason.
- Cross-slice communication should use public contracts, events, interfaces, or application-level orchestration.
- Data access can be local to the slice when the query is specific to the slice.
- Domain extraction happens after behavior proves it is shared or complex, not before.

## Vertical Slice Is Not An Excuse For Chaos

Vertical slices still need discipline:

- Names must be domain-based and intention-revealing.
- Handlers should remain readable.
- Long handlers should be refactored into local functions or local domain objects.
- Shared platform concerns stay outside slices.
- Tests define the behavior contract.

If a handler becomes a 400-line jungle, the answer is not "Vertical Slice is bad." The answer is "the slice is hiding too many concepts." Like lemari mainan anak: bukan berarti lemari salah, isinya saja perlu dirapikan.

## Relationship To Domain Models

Vertical Slice Architecture can coexist with domain models.

Use a simple transaction script when:

- The behavior is mostly validation plus persistence.
- Rules are local and unlikely to be reused.
- There is no meaningful domain invariant yet.

Extract a domain object or policy when:

- Several slices repeat the same business decision.
- Rules have names used by the business.
- A behavior has invariants that must hold together.
- Tests become easier when the rule is isolated.

Do not extract a domain model just to look sophisticated. A small function that tells the truth is better than a grand abstraction that asks for applause.

## Relationship To Shared Layers

This preset avoids broad layers such as:

- `controllers/`
- `services/`
- `repositories/`
- `models/`
- `utils/`

Those folders are not forbidden, but they are suspicious when they become dumping grounds.

Use shared folders only for stable cross-cutting concerns:

- HTTP router/bootstrap
- Database connection and transaction helpers
- Logging, tracing, metrics
- Authentication/session plumbing
- Queue clients or external SDK wrappers
- Common test fixtures with multiple real users

Shared code must be boring. If shared code contains feature-specific business rules, it probably belongs back in a slice.

## Choosing Slice Granularity

Prefer one slice per behavior, not one slice per noun.

Good slice names:

- `create_order`
- `cancel_order`
- `list_customer_invoices`
- `sync_inventory_snapshot`
- `approve_refund`

Risky slice names:

- `order`
- `customer`
- `invoice_service`
- `manager`
- `common`

Noun-only names often become mini-monoliths. A slice name should answer: "What behavior lives here?"

## Change Workflow

When implementing a feature:

1. Name the behavior.
2. Locate the existing slice or create a new slice folder.
3. Write or update the behavior test.
4. Implement the smallest local code needed.
5. Keep changes inside the slice unless a shared contract truly changed.
6. Run slice-level tests first.
7. Run broader tests only when shared code or public contracts changed.

If the change touches five slices, stop and ask whether this is really one behavior, a shared contract change, or a disguised refactor.

## Review Checklist

Use this checklist before calling a slice complete:

- Can a new reader find the behavior by folder name?
- Does the behavior mostly live inside one slice?
- Are cross-slice dependencies absent or explicit?
- Did we avoid generic shared abstractions without real callers?
- Does the test prove observable behavior?
- Is the simplest local implementation enough for today's requirement?
- Are names based on the domain and user intent?
- Did we leave unrelated slices untouched?

## Anti-Patterns

Avoid these:

- Creating a global `services` folder and calling it vertical slice.
- Putting every database operation in one shared repository.
- Requiring every request to pass through the same layered template.
- Sharing DTOs across unrelated slices.
- Extracting helpers after the first duplication.
- Hiding business rules in framework middleware.
- Testing mocks of layers instead of behavior.

## External References

- Jimmy Bogard, "Vertical Slice Architecture": https://www.jimmybogard.com/vertical-slice-architecture/
- Dan North, "CUPID: for joyful coding": https://dannorth.net/blog/cupid-for-joyful-coding/
- Martin Fowler, "Yagni": https://martinfowler.com/bliki/Yagni.html

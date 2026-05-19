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
  - feature slice structure
  - vertical slice folders
  - slice folder structure
related:
  - "[[docs/architecture/vertical-slice-architecture]]"
  - "[[docs/foundation/cupid-yagni-principles]]"
  - "[[docs/process/incremental-test-workflow]]"
  - "[[docs/decisions/0001-orientation-lock]]"
---

# Feature Slice Structure

This document defines where files go when the project uses the `vertical-cupid-incremental` orientation.

The default rule is: put code near the behavior it serves. Do not start by sorting files into technical drawers. A spoon goes near the plate, not in a museum of metal objects.

## Recommended Base Structure

Use this shape for a new backend or service project unless the existing stack requires a different entrypoint:

```text
project/
|-- cmd/
|   `-- <app>/
|       `-- main.go
|-- internal/
|   |-- app/
|   |   |-- bootstrap.go
|   |   |-- routes.go
|   |   `-- lifecycle.go
|   |-- platform/
|   |   |-- config/
|   |   |-- database/
|   |   |-- http/
|   |   |-- logging/
|   |   |-- messaging/
|   |   `-- observability/
|   `-- features/
|       `-- <feature_area>/
|           `-- <slice_name>/
|               |-- request.go
|               |-- handler.go
|               |-- validator.go
|               |-- result.go
|               |-- persistence.go
|               `-- slice_test.go
|-- docs/
|   |-- architecture/
|   |-- decisions/
|   |-- foundation/
|   `-- process/
|-- migrations/
`-- scripts/
```

For non-Go projects, keep the same ownership idea:

```text
src/
|-- app/
|-- platform/
`-- features/
    `-- <feature_area>/
        `-- <slice_name>/
            |-- request.*
            |-- handler.*
            |-- validator.*
            |-- result.*
            |-- persistence.*
            `-- *.test.*
```

## When To Use Feature Area Folders

Use `features/<feature_area>/<slice_name>` when several slices clearly belong to one product area.

Example:

```text
internal/features/billing/
|-- create_invoice/
|-- send_invoice/
|-- list_invoices/
`-- void_invoice/
```

Feature area names should be business words:

- `billing`
- `booking`
- `inventory`
- `membership`
- `notification`

Avoid technical area names:

- `controllers`
- `repositories`
- `requests`
- `handlers`
- `services`

Technical names are allowed inside the slice as file names, because there they serve the behavior instead of becoming the architecture.

## Standard Slice Files

A command slice can use this shape:

```text
internal/features/billing/create_invoice/
|-- command.go
|-- handler.go
|-- validator.go
|-- result.go
|-- persistence.go
`-- slice_test.go
```

A query slice can use this shape:

```text
internal/features/billing/list_invoices/
|-- query.go
|-- handler.go
|-- filters.go
|-- row.go
|-- persistence.go
`-- slice_test.go
```

An HTTP-focused slice can use this shape:

```text
internal/features/booking/cancel_booking/
|-- endpoint.go
|-- request.go
|-- handler.go
|-- response.go
|-- persistence.go
`-- slice_test.go
```

Do not force every slice to have every file. Empty ceremonial files are just furniture nobody sits on.

## File Responsibility Guide

Use these names consistently when they fit:

| File | Responsibility |
| --- | --- |
| `request.go` | Transport input shape, parsing-related input model |
| `command.go` | State-changing application input |
| `query.go` | Read-only application input |
| `validator.go` | Input validation and user-facing validation failures |
| `handler.go` | Orchestrates the slice behavior |
| `result.go` | Application result model |
| `response.go` | Transport response model or mapper |
| `persistence.go` | Slice-local database query or write operation |
| `events.go` | Events emitted by the slice |
| `policy.go` | Local business rule used by the slice |
| `slice_test.go` | Behavior tests for the slice |

If a file grows too large, split by concept using domain names, not generic words.

Good:

```text
pricing_policy.go
inventory_reservation.go
payment_authorization.go
```

Weak:

```text
helpers.go
utils.go
manager.go
common.go
```

## App And Platform Folders

`internal/app` wires the application:

- Load configuration.
- Create database and queue clients.
- Register routes.
- Start and stop background workers.
- Connect features to platform dependencies.

`internal/platform` owns technical capabilities:

- Database connection and transaction primitives
- HTTP server/router adapters
- Logging and tracing
- Message broker clients
- External service clients
- Clock, ID generator, and other infrastructure primitives

Platform code must not know feature rules. Platform is the road; features are the destinations. Jangan sampai aspal ikut menentukan mau makan bakso atau soto.

## Shared Code Rules

Create shared code only when one of these is true:

- At least two slices use the same behavior today.
- The code is platform plumbing, not business behavior.
- The code represents a named domain concept shared by multiple slices.
- A public contract must be stable across slices.

Before extracting shared code, write down:

- Which slices use it.
- Which behavior it owns.
- Which behavior it must not own.
- Which tests protect it.

If the answer is "maybe future slices will need it," keep it local. Future slices are not here to defend themselves.

## Cross-Slice Communication

Prefer these patterns:

- The app layer coordinates two slices through explicit calls.
- A slice emits an event and another slice subscribes.
- Shared domain policy is extracted only after multiple slices prove the need.
- External contracts are represented with small interfaces near the caller.

Avoid:

- Importing another slice's persistence model.
- Calling another slice's private helper.
- Sharing request/response structs between unrelated endpoints.
- Creating a central service that every slice must pass through.

## Tests Placement

Keep tests close to the slice:

```text
internal/features/billing/create_invoice/slice_test.go
```

Use broader integration tests only when:

- Multiple slices must cooperate.
- Platform wiring is part of the behavior risk.
- Persistence behavior depends on real database constraints.
- A public API contract changed.

The closest meaningful test runs first. The wider test runs when the change actually crosses a wider boundary.

## Migration Placement

Database migrations stay in a central `migrations/` folder because databases usually apply migrations globally and in order.

Name migrations by behavior when possible:

```text
202605190930_create_invoice_tables.sql
202605191015_add_invoice_status_index.sql
```

The slice owns the reason for a schema change. The migration folder owns the mechanics of applying it.

## Documentation Placement

For each important feature area, create a note when the behavior is not obvious:

```text
docs/modules/billing.md
```

Document:

- User-visible behaviors
- Important slice names
- Shared policies
- External contracts
- Known trade-offs

Do not document every file. Document decisions future humans will otherwise have to rediscover by archaeology.

## Slice Creation Checklist

Before creating a new slice:

- Can the behavior be named as a command, query, or workflow?
- Does an existing slice already own this behavior?
- Is the behavior small enough to test directly?
- Are dependencies clear and few?
- Is shared code truly needed now?

After creating a slice:

- The folder name describes behavior.
- The handler is readable without jumping through unrelated folders.
- Tests sit beside the slice.
- Platform dependencies enter through explicit parameters or constructors.
- No unrelated slice was modified by accident.

## Refactoring Checklist

Refactor a slice when:

- The handler is hard to read.
- A rule has a stable domain name.
- Two or more slices repeat the same policy.
- Test setup becomes more important than behavior.
- A local persistence query becomes shared and stable.

Do not refactor just because the folder looks different from another slice. Vertical Slice Architecture allows different slices to use different internal designs when their complexity differs.

## Completion Evidence

A completed vertical slice should leave this evidence:

- Code is mostly inside one slice folder.
- Shared changes are justified by real callers.
- Slice-level test command is known and runnable.
- Broader test command is run when shared/platform/public contract changed.
- Any new architecture decision is linked from `docs/decisions/`.

This is how Compass keeps freedom without becoming "bebas tapi nyasar."

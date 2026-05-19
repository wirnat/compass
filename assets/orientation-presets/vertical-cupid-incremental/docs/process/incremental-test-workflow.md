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
  - incremental tests
  - test after
  - slice testing
related:
  - "[[docs/architecture/vertical-slice-architecture]]"
  - "[[docs/architecture/feature-slice-structure]]"
  - "[[docs/foundation/cupid-yagni-principles]]"
---

# Incremental Test Workflow

This project uses incremental tests to keep feature slices small and verifiable.

The workflow is test-conscious, not ceremony-first. Test first when the behavior is clear. Test immediately after when discovery is needed. Never finish a slice with only hope as verification. Hope is not a test runner, Nak.

## Goal

Every completed slice should have evidence that its observable behavior works.

The evidence may be:

- A unit test for local policy or decision logic
- A slice-level test for command/query behavior
- An integration test for database or platform behavior
- A contract/API test for public interface behavior
- A documented manual verification only when automation is not practical

Manual verification is the exception, not the family business.

## Standard Workflow

Use this loop for most changes:

1. Name the behavior.
2. Define the smallest observable outcome.
3. Choose the closest useful test level.
4. Add a focused test before implementation when practical.
5. Implement the smallest code that passes.
6. Refactor inside the slice.
7. Run the slice test command.
8. Broaden tests only if shared code, platform code, persistence, or public contracts changed.
9. Record any decision that changes architecture or slice boundaries.

This keeps feedback short. Small loop first, bigger loop only when the blast radius is bigger.

## Choosing Test Level

| Change type | First test level | Broader verification |
| --- | --- | --- |
| Pure calculation or policy | Unit test beside the policy | Slice test if wired into behavior |
| Command handler | Slice-level handler test | Integration test if persistence or events matter |
| Query handler | Slice-level query test | Database integration test for SQL/ORM behavior |
| HTTP endpoint | Handler or endpoint test | API/contract test when public behavior changes |
| Database migration | Migration/integration test | Smoke test affected slices |
| Shared platform helper | Unit/integration test for helper | Run affected slice tests |
| Cross-slice workflow | Workflow/integration test | Run tests for all participating slices |

The closest useful test is the one that can fail for the right reason without requiring the entire universe to boot.

## Test-First Rule

Prefer test-first when:

- The expected behavior is clear.
- A bug is being fixed.
- A public contract is being changed.
- A business rule is known.
- A slice already exists and only needs new behavior.

Use the test to name the behavior before implementation.

Example:

```text
should_reject_refund_when_invoice_is_not_paid
should_list_only_active_memberships
should_emit_inventory_reserved_event
```

## Test-Immediately-After Rule

Test immediately after when:

- The implementation path is exploratory.
- You are learning an unfamiliar framework.
- The slice is mostly UI/adapter wiring.
- A spike is needed to discover the shape.

This is not permission to skip testing. It is permission to think with your hands, then write down what your hands learned.

After discovery:

1. Remove throwaway code.
2. Keep the smallest working behavior.
3. Add regression tests.
4. Refactor only what the tests protect.

## Slice Checkpoints

Stop at these checkpoints:

### Checkpoint 1: Behavior Named

Evidence:

- Slice name is a command, query, or workflow.
- Expected outcome is written in issue, test name, or docs.
- Non-goals are clear enough to avoid building extras.

### Checkpoint 2: Test Chosen

Evidence:

- Closest useful test level is selected.
- The test fails before implementation when practical.
- Test data uses domain language.

### Checkpoint 3: Local Implementation

Evidence:

- Code mostly lives inside one slice.
- Shared code was not changed without reason.
- Handler remains readable.

### Checkpoint 4: Refactor

Evidence:

- Names are domain-based.
- Repeated rules are either intentionally duplicated or extracted with real callers.
- No unrelated slice was refactored.

### Checkpoint 5: Verification

Evidence:

- Slice test command was run.
- Broader test command was run when boundary changes required it.
- Any unrun test has a clear reason.

## When To Broaden Verification

Run broader tests when the change touches:

- Shared platform code
- Public API or message contracts
- Database schema or migration
- Authentication/authorization behavior
- Cross-slice workflow
- Shared domain policy
- Error handling used by multiple features

Do not run a giant suite out of habit if a focused suite gives the needed evidence. But do run the giant suite when the change has giant shoes.

## Refactoring Rules

Allowed during a slice:

- Rename local concepts for clarity.
- Split a long handler into local functions.
- Extract a local policy object.
- Delete dead local code.
- Move code into shared only when a real second caller exists.

Avoid during a slice:

- Reorganizing unrelated features.
- Creating a new global layer.
- Renaming broad packages without need.
- Converting multiple slices to a new style because one slice changed.
- Adding abstractions that tests do not need.

One slice at a time. Kalau semua kamar dibereskan sekaligus, biasanya yang hilang duluan adalah gunting.

## Bug Fix Workflow

For bugs:

1. Reproduce the bug with the smallest failing test.
2. Place the test beside the slice that owns the behavior.
3. Fix the behavior locally.
4. Run the failing test until it passes.
5. Run nearby tests for the same feature area.
6. Broaden only if the fix touches shared code.

Do not fix a bug by changing shared code first unless the failing evidence shows the shared code is the source.

## New Feature Workflow

For new features:

1. Create or select the slice folder.
2. Write the happy path first.
3. Add important failure paths.
4. Keep edge cases tied to real requirements.
5. Delay generic infrastructure until a real behavior needs it.
6. Document any new public contract.

The first version should be boring, useful, and testable.

## What Counts As Done

A slice is done when:

- The behavior is implemented.
- The closest useful automated test passes, or a manual verification exception is recorded.
- Shared changes are justified.
- Naming follows the domain.
- No unrelated files were refactored.
- The final verification command is known.

## Anti-Patterns

Avoid:

- "I tested it in my head."
- Adding broad mocks that only prove the mock was called.
- Writing tests after a large refactor and pretending they guided the design.
- Building a reusable framework before two slices need it.
- Using low coverage as an excuse not to add a focused regression test.
- Running only broad tests and never testing the slice directly.

## Completion Note Template

Use this shape in implementation summaries:

```text
Behavior: <slice behavior>
Primary files: <slice files>
Verification: <commands run>
Shared changes: <none or justified list>
Deferred: <known non-goals or follow-up>
```

This template helps future agents see the boundary of the work quickly.

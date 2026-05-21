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
  - engineering philosophy
related:
  - "[[docs/foundation/architecture-principles]]"
  - "[[docs/foundation/testing-principles]]"
---

# Engineering Philosophy

This document defines the daily working principles for humans and agents changing this project. Architecture principles provide boundary direction; this philosophy keeps small decisions healthy. Projects rarely break because of one grand decision. They usually break because of many small decisions that each seem harmless alone.

## Keep It Small

Keep files, functions, packages, and scopes as small as they can be while staying clear.

Practical implications:

- one file has one primary reason to change
- one function does one job that can be explained briefly
- one package or component has clear ownership
- large changes are split into small verifiable steps
- do not create an abstraction just because it might be needed later

## Think Six Months Ahead

Every technical decision should ask:

> Will this make maintenance harder six months from now, or when the project becomes larger?

If the answer is "probably yes", simplify the design.

Thinking six months ahead does not mean over-engineering. It means choosing a simple design that does not lock the future.

## Junior-Readable Code

Code must be easy to read and understand, even for a junior developer.

Practical rules:

- names must honestly describe business or technical intent
- avoid clever code that needs a long explanation
- choose an explicit flow when it makes behavior easier to see
- do not hide important rules inside generic helpers
- if a reader must jump across many files to understand a simple flow, review the design

## Named Constants For Shared Values

Repeated or contract-sensitive values should have one clear name.

Practical rules:

- avoid bare literal strings for statuses, event names, routes, permissions, configuration keys, feature flags, error codes, provider names, and cross-boundary identifiers
- define named constants close to the owner of the concept
- keep constants grouped by responsibility, not in a generic dumping ground
- use the constant everywhere the value represents the same concept
- allow local literals only when the value is incidental, used once, and not part of a contract or rule

## Intuitive Comments Are Mandatory

Comments must help readers understand:

- why something is done
- important assumptions
- business rules
- edge cases
- non-obvious decisions

Comments should not explain mechanical details that the code already says. Use comments when readers need context that is not visible from names and structure.

## Tests Are Behavior Checks

Tests should be cheap, easy to run, and strong enough to prove the behavior being protected.

Practical rules:

- write tests from the perspective of expected consumer behavior
- choose the cheapest test level that still proves the behavior
- avoid testing private details unless they are part of the contract
- use fakes or mocks only when they make the test more focused
- if tests break during refactors without behavior changes, the tests are probably too attached to implementation

## Daily Checklist

- Is there a file or function that can be made smaller?
- Are names easy to understand?
- Will this decision still make sense six months from now?
- Can a junior developer follow the flow?
- Are repeated or contract-sensitive values named as constants instead of repeated literal strings?
- Do comments explain important reasons, not obvious mechanics?
- Do tests prove behavior, not implementation details?
- Does any abstraction still lack a real need?

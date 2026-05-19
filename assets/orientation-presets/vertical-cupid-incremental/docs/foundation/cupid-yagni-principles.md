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
  - CUPID
  - YAGNI
  - KISS
  - simple design
related:
  - "[[docs/architecture/vertical-slice-architecture]]"
  - "[[docs/architecture/feature-slice-structure]]"
  - "[[docs/process/incremental-test-workflow]]"
---

# CUPID, YAGNI, And KISS Principles

This project favors simple, local design pressure over speculative abstraction.

CUPID is used as a set of design properties, not as a moral scoreboard. YAGNI prevents future-fantasy code. KISS keeps the current solution understandable.

## Research Basis

Dan North frames CUPID as properties for joyful coding: Composable, Unix philosophy, Predictable, Idiomatic, and Domain-based. The useful point is that these are assessable properties, not rigid laws.

Martin Fowler describes YAGNI as not building a capability merely because we presume it will be needed later. YAGNI works best with tests and refactoring, because simple code must still be allowed to evolve.

This preset combines those ideas with Vertical Slice Architecture: keep behavior local, keep code predictable, and only extract structure when real behavior asks for it.

## Principle 1: Composable

Code is composable when it can be combined with other code without surprising side effects.

Prefer:

- Small public surface area
- Clear input and output
- Explicit dependencies
- No hidden global state
- Functions or objects that can be used in tests without booting the whole application

Avoid:

- Helpers that mutate shared state quietly
- Constructors that connect to networks
- Functions that read configuration without being told
- Shared objects whose behavior changes depending on call order

Review questions:

- Can this unit be used by a test with minimal setup?
- Are dependencies visible from the function signature or constructor?
- Does the caller know what will happen?

## Principle 2: Unix Philosophy

Each unit should do one thing well and compose with other units.

In this project, "one thing" means one coherent purpose from the caller's point of view. It does not mean one tiny class per line of thought.

Prefer:

- One slice for one behavior
- One handler for one command/query/workflow
- Local helpers that serve the slice's behavior
- Pipelines where each step has a clear purpose

Avoid:

- A `Manager` that validates, persists, publishes events, formats responses, and also makes coffee
- A shared service with methods for unrelated business areas
- Premature separation where every small step becomes a global abstraction

The key question: can a reader state what this unit is for in one sentence?

## Principle 3: Predictable

Code is predictable when names, tests, and contracts make behavior unsurprising.

Prefer:

- Domain-based names
- Deterministic behavior
- Explicit error handling
- Tests for important outcomes
- Logs that describe business milestones without leaking secrets

Avoid:

- Boolean parameters with unclear meaning
- Magic defaults hidden in deep helpers
- Time, randomness, or environment reads scattered through business code
- Functions that sometimes return errors and sometimes silently ignore failures

Predictability is where tests earn their rice. A passing test is not just decoration; it is a little fence so the code does not run into the street.

## Principle 4: Idiomatic

Code should feel natural in its language, framework, and local codebase.

Prefer:

- Existing project conventions
- Standard library patterns before custom frameworks
- Local naming style
- Error handling consistent with the surrounding code
- The simplest feature of the language that expresses the idea

Avoid:

- Importing patterns from another language without adapting them
- Over-designing because a blog post used a bigger system
- Creating a private framework inside the project
- Fighting the existing stack without strong reason

Idiomatic does not mean copying everything already present. If the current code has a bad habit, improve it locally and document the decision.

## Principle 5: Domain-Based

Code should model the problem domain in language and structure.

Prefer names users or domain experts understand:

- `approve_refund`
- `reserve_inventory`
- `expire_membership`
- `calculate_late_fee`

Avoid generic names:

- `process_data`
- `handle_logic`
- `do_stuff`
- `manager`
- `common`

When the code uses domain language, tests become easier to read and reviews become less like decoding secret cave paintings.

## YAGNI Rule

Do not build a capability before there is a real behavior, caller, or test that needs it.

Before adding an abstraction, ask:

- Who calls it today?
- Which behavior becomes simpler today?
- Which test proves it?
- What is the cost if we wait?
- Is this future need certain, or only a feeling wearing a helmet?

Allowed reasons to build now:

- The current behavior needs it.
- A public contract would be expensive to change later.
- A security, data integrity, or compliance requirement demands it.
- Two or more current slices use the same stable behavior.

Weak reasons:

- "We might need it later."
- "This is how enterprise apps look."
- "The architecture diagram has a box for it."
- "It feels cleaner."

Feeling cleaner is not evidence. Sometimes it is just the code wearing perfume.

## KISS Rule

Prefer the simplest design that handles the current behavior and leaves a clear path to grow.

Simple does not mean careless. Simple means:

- Fewer moving parts
- Fewer hidden assumptions
- Fewer names to remember
- Faster feedback
- Easier deletion

Use a simple local implementation when behavior is new or uncertain.

Use a more explicit design when:

- Rules are repeated.
- Invariants are important.
- Multiple teams touch the same behavior.
- Failure modes are costly.
- The public contract is hard to change.

## DRY With Caution

Do not treat duplication as automatically bad.

Duplicate temporarily when:

- Two slices look similar but may evolve differently.
- The shared concept has no clear domain name yet.
- Extraction would create a generic helper.

Extract when:

- The duplicated rule has the same meaning.
- The same change would need to be made in multiple places.
- The extracted name is domain-based.
- Tests can describe the shared behavior directly.

The first duplication is information. The second duplication is evidence. The third duplication is the universe tapping your shoulder.

## Review Checklist

Use this checklist in every meaningful change:

- Composable: are dependencies explicit and small?
- Unix: does each unit have one clear purpose?
- Predictable: can behavior be inferred from names, contracts, and tests?
- Idiomatic: does the code match the language and project style?
- Domain-based: do names come from the problem domain?
- YAGNI: is every abstraction needed by behavior today?
- KISS: is this the simplest design that preserves correctness?

## Anti-Patterns

Avoid:

- Abstracting after one use.
- Creating `utils` as a hiding place for unnamed ideas.
- Adding interfaces only to satisfy a pattern.
- Making all slices identical even when their complexity differs.
- Using "simple" as an excuse for untested risky behavior.
- Using "future proof" as an excuse for speculative design.
- Turning CUPID into a checklist that blocks delivery without improving code.

## Completion Evidence

Before completing work under this preset, leave evidence:

- New abstractions have current callers.
- Shared code has a stable name and tests.
- Slice behavior is tested at the closest useful level.
- Code names use domain language.
- Any deliberate trade-off is documented in a decision note or module note.

## External References

- Dan North, "CUPID: for joyful coding": https://dannorth.net/blog/cupid-for-joyful-coding/
- Martin Fowler, "Yagni": https://martinfowler.com/bliki/Yagni.html
- Jimmy Bogard, "Vertical Slice Architecture": https://www.jimmybogard.com/vertical-slice-architecture/

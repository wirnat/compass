---
type: design
status: active
owner: engineering
created: 2026-05-21
updated: 2026-05-21
parent: "[[docs/process/README]]"
tags:
  - docs/process
  - status/active
  - compass/task-memory
related:
  - "[[docs/decisions/0001-orientation-lock]]"
  - "[[docs/architecture/existing-architecture-lock]]"
  - "[[docs/process/existing-process-lock]]"
---

# Compass Task Memory Design

## Purpose

Compass works slice by slice. That is useful for agentic coding because each
slice creates a checkpoint and limits blast radius. The weak point appears when
LLM context is lost, compacted, or a task resumes in another session.

Task memory gives long Compass work a durable goal artifact under the client
project's `docs/` directory. It records the shared goal, planned slices, current
slice status, visual checkpoint map, summaries, and chronological memory so a
future agent can resume without changing the goal by accident.

## Scope

Task memory is only for long or risky multi-slice work. It must not slow normal
developer flow for small bug fixes, docs-only updates, or one-slice changes.

Compass creates task memory only when both conditions are true:

1. The task type or discovered risk suggests long-running work, such as
   `new_feature`, `architecture_change`, large refactor, or another task with
   meaningful checkpoint risk.
2. After align-context or fit-design, Compass has at least two concrete slices
   that both developer and agent understand.

Task memory is created after the goal is aligned and before the first
implementation slice begins.

## Repository Fit

This design follows the repository's `existing-architecture-lock`:

- `SKILL.md` remains the Compass behavior entrypoint.
- `references/task-memory.xml` will hold structured task memory rules.
- `assets/docs-seed/_templates/` will hold reusable task memory templates.
- `docs/` will record this repository's own decision and process impact.
- No new root architecture folder is needed.

## Folder Shape

When task memory is required, Compass creates this structure in the target
project:

```text
docs/.tasks/
  <YYYYMMDD-HHMM>_<goal_slug>/
    goal.md
    diagram.md
    memories.md
```

The timestamp uses local project/session time when known. `goal_slug` is a short
kebab-case version of the agreed goal name.

## Goal File

`goal.md` is the source of truth for the active goal. It records:

- goal name
- goal status
- goal description
- non-goals
- success criteria
- slices and slice status
- link to previous or next goal when superseded
- latest evidence

Goal statuses:

- `active`: goal is currently in progress
- `completed`: goal is finished and verified
- `superseded`: goal was replaced by a new goal
- `cancelled`: goal stopped without a replacement

Slice statuses:

- `pending`: slice is planned but not started
- `active`: slice is currently being worked on
- `done`: slice is complete and verified
- `blocked`: slice cannot proceed until a blocker is resolved

When a slice changes but the goal remains stable, Compass updates the same task
folder. When the goal changes, Compass creates a new task folder, marks the old
goal as `superseded`, and links the old and new goals.

## Diagram File

`diagram.md` contains a short explanation, a Mermaid diagram, legend, and text
fallback. It visualizes the path from goal alignment through slices to the final
goal.

Color rules:

- `done`: green
- `active`: blue
- `pending`: gray
- `blocked`: red

The diagram must be updated whenever task memory is updated. If Mermaid does
not render, the text fallback must still show slice order and current status.

## Memories File

`memories.md` has two sections.

```md
## SUMMARIES

Ringkasan percakapan, goal aktif, posisi terakhir, dan keputusan utama.

## HISTORIES

[YYYY-MM-DD HH:mm TZ]
User memikirkan:
...

LLM memikirkan:
...

Kesepakatan:
...
```

`SUMMARIES` stores the current compressed state for a future LLM. `HISTORIES`
stores entries from newest to oldest.

The `LLM memikirkan` field must contain a rationale snapshot, not private
chain-of-thought. It should record useful assumptions, trade-offs, risks, and
decision reasons.

## Lifecycle

Compass updates task memory at these moments:

1. After the task memory folder is first created.
2. When a slice starts: mark the slice `active` and update the diagram.
3. When a slice completes: mark it `done`, record evidence, and update the
   diagram.
4. When a slice is blocked: mark it `blocked`, record the blocker, and update
   the diagram.
5. When slices change but goal stays the same: update `goal.md`, `diagram.md`,
   and `memories.md`.
6. When the goal changes: create a new folder, mark the old goal `superseded`,
   cross-link both goals, and record the reason.
7. When the goal completes: mark the goal `completed` and record final evidence.

At the start of a long Compass task, Compass should inspect `docs/.tasks/` for
an active relevant goal before creating a new one. This prevents accidental
duplicate task memories after context loss.

## Files To Change

Implementation should make these repository changes:

- Add `references/task-memory.xml`.
- Update `SKILL.md` to load task memory rules for long multi-slice tasks,
  post-fit-design creation, slice transitions, and resume checks.
- Add templates:
  - `assets/docs-seed/_templates/task-goal.md`
  - `assets/docs-seed/_templates/task-diagram.md`
  - `assets/docs-seed/_templates/task-memories.md`
- Update Compass repository docs to describe task memory in process and
  architecture context.

## Verification

This repository does not currently have a test runner. Verification should use
the available project evidence:

- Confirm the XML reference is well-formed.
- Confirm the new template files exist.
- Run `./scripts/bootstrap-docs.sh --target <temp-dir> --preset existing-architecture-lock --dry-run`.
- Run `./scripts/bootstrap-docs.sh --target <temp-dir> --preset existing-architecture-lock`.
- Confirm generated docs include the task memory templates.
- Confirm existing orientation and workflow docs remain intact.

## Open Decisions

None. The agreed design choices are:

- Task memory applies only to long or risky multi-slice work.
- Activation uses both task-risk signal and 2+ concrete slices.
- Creation happens after align-context or fit-design.
- `diagram.md` stores the Mermaid diagram plus text support.
- Goal status values are `active`, `completed`, `superseded`, and `cancelled`.
- Slice status values are `pending`, `active`, `done`, and `blocked`.

---
type: task-goal
status: active
owner: engineering
created: "{{datetime:YYYY-MM-DD HH:mm TZ}}"
updated: "{{datetime:YYYY-MM-DD HH:mm TZ}}"
parent: "[[docs/.tasks]]"
tags:
  - docs/tasks
  - status/active
goal_id: "{{goal_id}}"
goal_status: active
previous_goal:
next_goal:
aliases:
related:
---

# {{goal_name}}

## Status

`active`

## Description

{{goal_description}}

## Approved Scope

{{approved_scope}}

## Non-Goals

- {{non_goal}}

<!-- Optional. Remove Do and Don't when the goal has no guardrails. -->
## Do

Rules that must hold while working on this goal. Keep them concrete and checkable, about five at most.

- {{goal_specific_rule}}

## Don't

Things that must not happen, each with its reason. Record an approach the developer rejected here, so a future session does not take it again.

- {{forbidden_action_and_reason}}

## Success Criteria

- {{success_criterion}}

## Slices

| Slice | Status | Purpose | Evidence |
| --- | --- | --- | --- |
| {{slice_id}} - {{slice_name}} | pending | {{slice_purpose}} | {{slice_evidence}} |

## Latest Evidence

<!-- Replace this entry at each slice; record per-slice evidence in memories.md HISTORIES. -->
- {{latest_evidence}}

## Goal Links

- Previous goal: {{previous_goal_link}}
- Next goal: {{next_goal_link}}

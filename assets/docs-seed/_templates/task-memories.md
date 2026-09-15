---
type: task-memory
status: active
owner: engineering
created: "{{datetime:YYYY-MM-DD HH:mm TZ}}"
updated: "{{datetime:YYYY-MM-DD HH:mm TZ}}"
parent: "[[docs/.tasks/{{task_folder}}/goal]]"
tags:
  - docs/tasks
  - status/active
goal_id: "{{goal_id}}"
related:
  - "[[docs/.tasks/{{task_folder}}/goal]]"
  - "[[docs/.tasks/{{task_folder}}/diagram]]"
---

# {{goal_name}} Memories

## SUMMARIES

<!-- Rewrite at each checkpoint and keep this section near 40 lines. SUMMARIES and HISTORIES are Compass-required headings; add other sections as the project needs. -->
{{conversation_summary}}

### Brainstorming Summary

{{brainstorming_summary}}

### Align Context

{{align_context_summary}}

### Approved Design

{{approved_design_summary}}

### Decisions And Trade-offs

{{decisions_tradeoffs}}

### Open Questions

{{open_questions}}

### Verification Plan

{{verification_plan}}

## HISTORIES

[{{datetime:YYYY-MM-DD HH:mm TZ}}]
User memikirkan:
{{user_thought_snapshot}}

LLM memikirkan:
{{llm_rationale_snapshot}}

Kesepakatan:
{{agreement_snapshot}}

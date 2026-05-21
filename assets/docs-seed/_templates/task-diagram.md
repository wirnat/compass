---
type: task-diagram
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
  - "[[docs/.tasks/{{task_folder}}/memories]]"
---

# {{goal_name}} Diagram

## How To Read

The diagram shows the agreed goal path and slice checkpoint status. Green means
done, blue means active, gray means pending, and red means blocked.

```mermaid
flowchart LR
    align["Align Context"] --> s1["{{slice_1_short_name}}"]
    s1 --> goal["Goal: {{goal_short_name}}"]

    classDef pending fill:#3f3f46,stroke:#a1a1aa,color:#f4f4f5;
    classDef active fill:#0284c7,stroke:#7dd3fc,color:#ffffff;
    classDef done fill:#3f7d20,stroke:#86efac,color:#ffffff;
    classDef blocked fill:#b91c1c,stroke:#fca5a5,color:#ffffff;

    class align done;
    class s1 pending;
    class goal pending;
```

## Text Checkpoints

| Checkpoint | Status | Notes |
| --- | --- | --- |
| Align Context | done | Goal and slices agreed. |
| {{slice_1_short_name}} | pending | {{slice_1_note}} |
| Goal: {{goal_short_name}} | pending | Final goal is not complete yet. |

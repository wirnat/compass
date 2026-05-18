---
name: compass
description: Guide software engineering work by classifying the request, selecting the right workflow, enforcing gates, and bootstrapping durable project docs when they are missing. Use for features, fixes, refactors, architecture, docs, tests, migrations, tooling, performance, security, incidents, releases, or engineering workflow design in any software project.
metadata:
  short-description: Route engineering work with project principles
---

# Compass

## Purpose

Compass keeps engineering work pointed in the right direction before files change. It classifies the user's request, selects a workflow based on risk, enforces approval gates, and can seed a project with durable documentation principles.

Use this skill for software work in any language or stack. Do not add language-specific best practices here. Project and language details come from the repository being worked on.

## First Run Bootstrap

At the start of a Compass-guided task, check whether the current project has the seed documentation:

- `docs/README.md`
- `docs/foundation/engineering-philosophy.md`
- `docs/foundation/architecture-principles.md`
- `docs/foundation/documentation-principles.md`
- `docs/foundation/testing-principles.md`
- `docs/foundation/README.md`
- `docs/architecture/README.md`
- `docs/decisions/README.md`
- `docs/modules/README.md`
- `docs/process/README.md`
- `docs/process/implementation-workflow.md`
- `docs/reference/README.md`
- `docs/reference/note-schema.md`
- `docs/runbooks/README.md`
- `docs/_templates/README.md`

If any seed document is missing and the user has not forbidden file changes, run:

```bash
.skills/compass/scripts/bootstrap-docs.sh --target .
```

The bootstrap script is idempotent. It creates missing seed docs and does not overwrite existing files unless `--force` is explicitly used.

If the current workspace does not contain `.skills/compass/scripts/bootstrap-docs.sh`, tell the user the script is missing and continue with the classification workflow.

## Quick Start

1. Restate the user's request in one sentence.
2. Check and bootstrap missing seed docs when appropriate.
3. Classify the task using `references/classification.xml`.
4. Load the matching task definition from `references/task-types.xml`.
5. Load the matching workflow from `references/workflows.xml`.
6. Load `references/bootstrap-rules.xml` when docs need to be seeded.
7. Load `references/documentation-policy.xml` when creating or changing documentation.
8. Tell the user the task type, why it fits, and the workflow you will follow using the XML response shape below.
9. Execute only the next allowed phase. If a phase has an approval gate, stop at that gate and wait for explicit approval before continuing.
10. If implementation is requested, continue only after all earlier gated phases have explicit developer approval, then verify with the task's completion evidence.

## Hard Gates

- `new_feature` has three sequential phases: brainstorming, design, implementation.
- A single `new_feature` workflow may execute only one feature.
- If the user's request contains multiple features, split them into a TODO plan, ask or choose the first safe feature slice, and execute only that one feature through the gated workflow.
- Do not implement two features in one `new_feature` cycle, even when they share components or adapters.
- Brainstorming and design are planning-only phases. Do not edit files, create tests, run implementation commands, or apply patches during those phases, except the first-run docs bootstrap.
- Design must focus on the selected feature's contract, core model, and behavior-test matrix. Behavior scenarios must be ordered from common cases to edge cases until no obvious gap remains.
- After brainstorming, stop and ask whether to challenge the shared understanding or continue to design.
- After design, stop and ask whether to adjust suggested behavior or continue to implementation.
- Implementation may start only after the developer explicitly approves the design phase.
- Implementation must run as small manual checkpoints. Implement exactly one approved slice, run the relevant verification, stop, report what changed and what passed or failed, then ask the developer before continuing to the next slice.
- A general request such as "build feature Y" or "implement Z" is not approval to skip brainstorming and design. Treat it as the start of the `new_feature` workflow.
- If the user explicitly says to skip a phase, state the skipped gate and risk before continuing.

## Routing Rules

- Prefer the task type that controls risk, not the label the user used.
- If a task touches architecture boundaries, classify it as `architecture_change` even when it also adds behavior.
- If a task changes database schema, include `db_migration` as a secondary type even when the primary type is `new_feature`, `feature_update`, or `bug_fix`.
- If production is broken or urgent, classify it as `hotfix_incident` first.
- If the request is unclear, ask one classification question before planning.
- Do not create abstractions, files, or commits until the selected workflow calls for them, except first-run docs bootstrap.
- Do not treat TDD as permission to skip `new_feature` gates. TDD belongs inside the approved design and implementation phases.

## Reference Format

References use XML tags because the skill mixes task definitions, ordered workflows, gates, and output contracts. Treat tag names as semantic instructions, not decoration.

## Common Outputs

For planning or triage, respond with this XML shape:

```xml
<task-routing>
  <primary-type>task_type</primary-type>
  <secondary-type>task_type_or_none</secondary-type>
  <why>short reason</why>
  <workflow>
    <step>ordered step</step>
  </workflow>
  <evidence>tests/checks/docs needed</evidence>
  <commit-hint>Conventional Commit type</commit-hint>
</task-routing>
```

For implementation, keep the same classification internally and report it in the final answer.

## References

- `references/classification.xml`: decision tree and tie-breakers.
- `references/task-types.xml`: supported task taxonomy and commit mapping.
- `references/workflows.xml`: workflow checklist per task type.
- `references/bootstrap-rules.xml`: documentation bootstrap behavior.
- `references/documentation-policy.xml`: generic documentation taxonomy and source-of-truth rules.

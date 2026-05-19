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
- `docs/decisions/0001-orientation-lock.md`
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
- `docs/process/workflows.xml`
- `docs/reference/README.md`
- `docs/reference/note-schema.md`
- `docs/reference/orientation-presets.md`
- `docs/runbooks/README.md`
- `docs/_templates/README.md`

If any seed document is missing and the user has not forbidden file changes, do not immediately run the bootstrap script. First run `scripts/bootstrap-docs.sh --list-presets` or present the preset choices below, then ask the user to choose a preset and wait for the answer.

Resolve the script path relative to this `SKILL.md` file's directory, not relative to the target workspace. For example, if this skill is installed at `/Users/me/.codex/skills/compass/SKILL.md`, run `/Users/me/.codex/skills/compass/scripts/bootstrap-docs.sh --target "$PROJECT_DIR" --preset <selected-preset>`.

After the user chooses, run:

```bash
scripts/bootstrap-docs.sh --target . --preset <selected-preset>
```

The bootstrap script seeds reference material. Do not report the docs as finished until the copied preset docs are adapted to the target project's language, framework, and repository conventions. For example, `clean-solid-tdd` source docs may contain Go-oriented examples such as `cmd/`, `internal/`, `.go`, `module.go`, or `adapters/postgres`; for a TypeScript, Python, Swift, Kotlin, frontend, or other project, rewrite the generated docs to equivalent stack-idiomatic folders and file names without losing the architecture detail, dependency rules, testing gates, or completion evidence.

For `clean-solid-tdd`, review and adapt at minimum:

- `docs/architecture/folder-file-structure.md`
- `docs/architecture/clean-architecture.md`
- `docs/process/tdd-workflow.md`
- `docs/process/workflows.xml` when workflow wording mentions stack-specific files or folders

Detect the stack from existing project files when possible. If the project is empty or ambiguous, ask the developer which language or stack to target before adapting the docs. Do not create static stack profiles inside the Compass skill; the LLM adapts the generated docs from the selected preset references.

Exception: if the target project already has a coherent existing architecture, docs, conventions, and workflow that should be preserved, Compass may select `existing-architecture-lock` from observed evidence and run bootstrap with that preset. State the evidence before running it.

The bootstrap script is idempotent. It creates missing seed docs and does not overwrite existing files unless `--force` is explicitly used. It requires an explicit `--preset` to prevent accidental default bootstrapping.

If the skill directory does not contain `scripts/bootstrap-docs.sh`, tell the user the script is missing and continue with the classification workflow.

### Orientation Lock

Compass must lock architecture, foundation principles, and development workflow before implementation work begins. Do not silently default the lock when bootstrapping a project.

Available orientation presets:

- `clean-solid-tdd`: Enterprise-grade Clean Architecture layering, explicit folder/file structure, SOLID, and TDD. Best for frontend, backend, full-stack, API, and business systems that need protected dependency direction, clear boundaries, and test-first discipline.
- `vertical-cupid-incremental`: Vertical Slice Architecture, explicit feature-slice structure, CUPID/YAGNI/KISS, and incremental tests. Best for small to medium products that benefit from feature-local change, low ceremony, and avoiding over-layering.
- `ddd-solid-bdd`: Domain-Driven Design, explicit bounded-context structure, domain modeling principles, and BDD plus TDD. Best for complex business domains that need ubiquitous language, bounded contexts, aggregates, and executable behavior examples.
- `existing-architecture-lock`: preserve and document the existing project structure, principles, and workflow. Best for mature projects with coherent existing conventions that should be extended instead of replaced.
- `research-based`: search current sources, compare options, cite evidence, then lock the selected architecture, principles, and workflow. Best for unknown domains or when the user asks Compass to research alternatives.

When offering presets, include each preset name, short description, and when it fits. Ask the user to choose one before running `bootstrap-docs.sh`, unless selecting `existing-architecture-lock` from observed existing-project evidence.

If the user asks to search, research, compare current architecture options, or find another approach from the internet, use `research-based` and browse before writing the final lock. Prefer primary or authoritative sources.

If orientation docs already exist, read them before classifying or designing work. Do not replace an existing orientation lock unless the user explicitly asks to change the project direction.

### Preset Workflows

Each orientation preset provides its active task workflow as `docs/process/workflows.xml`. During bootstrap, Compass copies the selected preset process workflow into the target project's `docs/process/workflows.xml`.

When a project has `docs/process/workflows.xml`, read it after classification and use it as the active workflow. Compass must not use a root-skill workflow fallback and must not use `docs/reference/workflows.xml` as the active workflow source. If `docs/process/workflows.xml` is missing, stop before planning implementation work and seed or migrate the project's Compass docs first.

## Project Docs Integration

Compass must treat the target project's `docs/` directory as the automatic project context pack. A project that uses this skill does not need to duplicate or link Compass docs from `AGENTS.md`.

At the start of every Compass-guided task, after the first-run bootstrap check, read the available project docs needed to understand the task:

- Always read `docs/decisions/0001-orientation-lock.md` when it exists.
- Always read `docs/README.md`, `docs/process/workflows.xml`, and the relevant category README files for the selected task area.
- Read the architecture, foundation, and process docs linked by the orientation lock.
- Read relevant `docs/modules/` notes before touching a module, domain, package, feature area, bounded context, or slice.
- Read relevant `docs/decisions/` records before changing boundaries, dependencies, data ownership, contracts, build flow, or release flow.
- Read `docs/reference/` when changing schemas, public contracts, naming rules, note structure, or orientation presets.

If a referenced doc is missing, continue with the best available docs and record the gap in the task output. Do not ask the user to add Compass docs to `AGENTS.md`. If `AGENTS.md` exists, read it as repository instruction context only; it is not the documentation integration mechanism.

When planning or implementing, ground architecture, naming, test strategy, and documentation updates in the loaded project docs. If code and docs disagree, stop before broad changes and state the conflict.

## Language And Stack Adaptation

Preset docs are authoritative for principles and detail, not for copying language-specific filenames blindly. When bootstrapping a new project or repairing seed docs, Compass must adapt generated architecture and process docs to the developer's selected or detected language and framework.

Adaptation rules:

- Preserve the same architectural detail, rules, checklists, and evidence requirements.
- Translate folder names, file names, entrypoints, test placement, adapter names, and examples into idioms of the target stack.
- Keep Clean Architecture dependency direction intact even if the target stack has different naming conventions.
- Keep SOLID and TDD guidance intact while mapping test levels to the project's actual test runner and file conventions.
- Remove or rewrite examples that are only true for the reference language.
- Record the detected or selected stack in the adapted docs or bootstrap summary.

If the target stack is unknown, do not guess by copying Go-shaped examples. Ask the developer first. Menebak bahasa proyek itu seperti menebak isi rantang; bisa benar, tapi kalau salah satu keluarga makan sambal semua.

## Quick Start

1. Restate the user's request in one sentence.
2. Check missing seed docs and orientation lock. If docs are missing, offer preset choices before bootstrapping; do not auto-run bootstrap.
3. If bootstrap just ran, adapt copied preset docs to the target language or stack before treating docs as ready.
4. Build the project docs context from `docs/` using the Project Docs Integration rules.
5. Classify the task using `references/classification.xml`.
6. Load the matching task definition from `references/task-types.xml`.
7. Load the matching workflow from project `docs/process/workflows.xml`. If it is missing, do not use a fallback workflow; seed or migrate Compass docs first.
8. Load `references/bootstrap-rules.xml` when docs or orientation lock need to be seeded.
9. Load `references/documentation-policy.xml` when creating or changing documentation.
10. Tell the user the task type, why it fits, and the workflow you will follow using the XML response shape below.
11. Execute only the next allowed phase. If a phase has an approval gate, stop at that gate and wait for explicit approval before continuing.
12. If implementation is requested, continue only after all earlier gated phases have explicit developer approval, then verify with the task's completion evidence.

## Hard Gates

- `new_feature` has three sequential phases: brainstorming, design, implementation.
- A single `new_feature` workflow may execute only one feature.
- If the user's request contains multiple features, split them into a TODO plan, ask or choose the first safe feature slice, and execute only that one feature through the gated workflow.
- Do not implement two features in one `new_feature` cycle, even when they share components or adapters.
- Brainstorming and design are planning-only phases. Do not edit files, create tests, run implementation commands, or apply patches during those phases, except listing preset choices or running an approved first-run docs bootstrap.
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
- Do not create abstractions, files, or commits until the selected workflow calls for them, except an approved first-run docs bootstrap.
- Do not rely on `AGENTS.md` to discover Compass documentation. Use project `docs/` directly as the integrated context source.
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
  <workflow-source>docs/process/workflows.xml</workflow-source>
  <workflow>
    <step>ordered step</step>
  </workflow>
  <documentation-context>docs read, docs missing, or none found</documentation-context>
  <evidence>tests/checks/docs needed</evidence>
  <commit-hint>Conventional Commit type</commit-hint>
</task-routing>
```

For implementation, keep the same classification internally and report it in the final answer.

## References

- `references/classification.xml`: decision tree and tie-breakers.
- `references/task-types.xml`: supported task taxonomy and commit mapping.
- `assets/orientation-presets/<preset>/docs/process/workflows.xml`: preset-specific workflow copied to project `docs/process/workflows.xml`.
- `references/bootstrap-rules.xml`: documentation bootstrap behavior.
- `references/documentation-policy.xml`: generic documentation taxonomy and source-of-truth rules.

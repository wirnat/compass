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

## Session Update Gate

At the first Compass-guided task in each Codex session, before project bootstrap,
classification, planning, or implementation, verify that the installed Compass
skill matches the latest `main` revision from `https://github.com/wirnat/compass`.

When Compass was installed and is managed by the `skills` CLI, prefer the CLI
update path:

```bash
npx skills update
```

If the CLI update succeeds and updates Compass, re-open and follow the updated
`SKILL.md` before continuing. Do not continue from stale instructions after an
update.

If `npx` or the `skills` CLI is unavailable, the installed skill is not managed
by that CLI, or the CLI update cannot update Compass, use the bundled updater as
the fallback. Resolve paths relative to this `SKILL.md` file's directory, not
relative to the target workspace. Run:

```bash
scripts/update-skill.sh --skill-dir <installed-compass-skill-dir>
```

If either update path reports that Compass is already up to date, continue
normally.

If the bundled script updates the skill, re-open and follow the updated
`<installed-compass-skill-dir>/SKILL.md` before continuing.

If the CLI update is unavailable or fails and the fallback script is missing,
`git` is unavailable, the network check fails, or the fallback update fails,
stop before implementation or docs bootstrap work. Report the reason and ask
whether the developer wants to continue with the installed version for this
session. Do not silently skip this gate.

If the developer explicitly forbids updating or network checks for the session,
state that the Session Update Gate was skipped by request and continue only with
that risk visible.

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
- `docs/_templates/task-goal.md`
- `docs/_templates/task-diagram.md`
- `docs/_templates/task-memories.md`

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

For `infra-ops`, detect the toolchain, such as Terraform, Ansible, Helm, Kubernetes manifests, or Pulumi, and record it in `docs/decisions/0001-orientation-lock.md`. Rewrite the toolchain mapping in `docs/architecture/infrastructure-layout.md` and the generic plan, dry-run, and apply wording in `docs/process/workflows.xml` to the project's commands. If the toolchain is unknown, ask before adapting.

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
- `infra-ops`: declared-state infrastructure operations with risk-tiered live-change gates, plan or dry-run before apply, and live verification. Best for infrastructure, platform, and operations repositories such as IaC, configuration management, cluster manifests, and server fleets.

When offering presets, include each preset name, short description, and when it fits. Ask the user to choose one before running `bootstrap-docs.sh`, unless selecting `existing-architecture-lock` from observed existing-project evidence.

If the user asks to search, research, compare current architecture options, or find another approach from the internet, use `research-based` and browse before writing the final lock. Prefer primary or authoritative sources.

If orientation docs already exist, read them before classifying or designing work. Do not replace an existing orientation lock unless the user explicitly asks to change the project direction.

### Preset Workflows

Each orientation preset provides its active task workflow as `docs/process/workflows.xml`. During bootstrap, Compass copies the selected preset process workflow into the target project's `docs/process/workflows.xml`.

When a project has `docs/process/workflows.xml`, read it after classification and use it as the active workflow. Compass must not use a root-skill workflow fallback and must not use `docs/reference/workflows.xml` as the active workflow source. If `docs/process/workflows.xml` is missing, stop before planning implementation work and seed or migrate the project's Compass docs first.

If the selected task type has no matching `<workflow type="...">` in the active `docs/process/workflows.xml`, stop before planning implementation work. Report the unsupported workflow gap and ask whether to adapt the project's workflow file for this task type or reclassify the request. Do not silently borrow a workflow from another preset. When the developer chooses to adapt the workflow for `infra_change`, copy the `infra_change` workflow and the `<risk-tiering>` block from the Compass `infra-ops` preset (`assets/orientation-presets/infra-ops/docs/process/workflows.xml`) into the project's `docs/process/workflows.xml`, then adapt them.

## Project Docs Integration

Compass must treat the target project's `docs/` directory as the automatic project context pack. A project that uses this skill does not need to duplicate or link Compass docs from `AGENTS.md`.

At the start of every Compass-guided task, after the first-run bootstrap check, read the available project docs needed to understand the task:

- Always read `docs/decisions/0001-orientation-lock.md` when it exists, and `docs/process/workflows.xml`.
- Choose the remaining docs from the docs index instead of opening category READMEs and notes one by one. Run `scripts/docs-index.sh --target <project-dir>`, resolved relative to this `SKILL.md` file's directory. It prints a YAML list of `docs/` notes with path, type, status, summary, aliases, related, and code globs, generated on demand from frontmatter. Superseded and archived notes are skipped unless `--all` is passed.
- Select notes by matching the task topic against `summary` and `aliases`, matching the files you expect to touch against `code`, then following `related` one step. Load only the selected notes.
- The selection must still cover the architecture, foundation, and process docs linked by the orientation lock; relevant `docs/modules/` notes before touching a module, domain, package, feature area, bounded context, or slice; relevant `docs/decisions/` records before changing boundaries, dependencies, data ownership, contracts, build flow, or release flow; and `docs/reference/` when changing schemas, public contracts, naming rules, note structure, or orientation presets.
- If the script is missing or fails, fall back to reading `docs/README.md` and the relevant category README files, and record the fallback in the documentation context.
- Report index warnings, such as a `code` glob that matches no files, as documentation gaps.
- For symbol-level code lookup, use a code intelligence tool such as GitNexus when the agent has one. Compass does not require it.

For work with gated design context or long/risky multi-slice risk, run `scripts/docs-index.sh --tasks --target <project-dir>` after reading the orientation and process docs; it lists open goals from `goal.md` frontmatter so you do not open every task folder. If an active goal's `updated` date is more than 14 days old, offer to mark it `completed` or `cancelled` before selecting a goal. When closed goals are still present, offer close-out before starting new work. Report `--tasks` warnings as documentation gaps, and do not rewrite existing task memory without developer approval. If one active relevant goal exists, read its `goal.md` in full and the `SUMMARIES` section plus the newest `HISTORIES` entry of `memories.md` before planning or implementation. Read older histories or `diagram.md` only when the summaries are not enough; keep updating all three files. If multiple active goals could match the request, ask one clarification question before selecting one. If an active goal conflicts with the user's request, treat that as a possible goal change rather than silently reusing or overwriting it.

If a referenced doc is missing, continue with the best available docs and record the gap in the task output. Do not ask the user to add Compass docs to `AGENTS.md`. If `AGENTS.md` exists, read it as repository instruction context only; it is not the documentation integration mechanism.

When planning or implementing, ground architecture, naming, test strategy, and documentation updates in the loaded project docs. If code and docs disagree, stop before broad changes and state the conflict.

When implementation introduces or touches repeated or contract-sensitive values such as statuses, event names, routes, permissions, configuration keys, feature flags, error codes, provider names, or cross-boundary identifiers, avoid bare literal strings. Prefer named constants owned by the relevant module or boundary so the concept has one source of truth.

## Question Capability Policy

When Compass needs developer input during align-context, classification clarification, preset selection, approval gates, task-memory conflict selection, or stack clarification, prefer the active coding agent's structured question capability when one is available. Examples include an agent-native question tool, choice picker, or form-style prompt. If the active agent has no such capability, use a normal text question.

Keep this policy generic across coding agents:

- Do not require one vendor-specific tool name as the only valid mechanism.
- Ask only the next workflow-allowed question; do not bundle unrelated decisions.
- Include a recommended option when there is enough context to recommend one.
- Explain the reason, trade-off, or consequence for each option so the developer can decide quickly.
- Preserve hard gates: a structured question is still a request for explicit developer approval when the workflow requires approval.

## Local Runtime Policy

When a task needs to run the application, its dependencies, or integration or end-to-end tests on the developer's machine, treat machine resources as shared with every other project on it. Many developers do not notice duplicate containers, so the agent keeps the machine tidy:

- Read `docs/process/local-environment.md` first. If it is missing, record the gap and ask before creating it from `docs/_templates/local-environment.md` or the installed Compass template.
- Before starting containers, list what is already running with the project's container runtime, such as Docker or Podman. Reuse a running shared service, such as a database, cache, broker, or observability stack, instead of starting a duplicate.
- Start only the services the task needs, through compose profiles or named services, not a whole compose file for one test.
- Prefer the shared dev infrastructure named in `local-environment.md`. Start a project-owned copy only when that file says the project needs a different version or extension.
- When the task ends, stop what the agent started unless the developer wants it kept, and report anything left running.
- Never point local runs or tests at remote databases or shared staging services without explicit developer approval.

## Task Memory For Long Multi-Slice Work

Compass uses task memory to preserve context for long or risky work that has multiple implementation slices. Task memory is not created for every task.

Task memory is a pre-implementation hard gate. After align-context, fit-design, or the last approved design phase, implementation must not start until Compass reports one of these outcomes:

- `created`: new task memory folder was created for this goal
- `resumed`: one active relevant task memory folder was loaded and updated if needed
- `not-required`: the task has no gated design context to preserve and is below the long-work threshold

Load `references/task-memory.xml` when either condition is true:

- a Compass workflow with brainstorming, align-context, evidence-discovery, fit-design, design, baseline-discovery, or delta-design has reached developer-approved design context that must be preserved before implementation
- the task type or discovered risk suggests long-running work, such as `new_feature`, `architecture_change`, large refactor, or another task with meaningful checkpoint risk, and Compass has at least two concrete slices that the developer and agent understand

For gated design work, task memory is required even when the approved implementation has only one slice. Create or resume `docs/.tasks/<YYYYMMDD-HHMM>_<goal_slug>/` after design approval and before the first implementation slice starts. The folder must contain `goal.md`, `diagram.md`, and `memories.md`, based on the task memory templates from `docs/_templates/`.

When saving gated design context, preserve the approved brainstorming, align-context, and design outputs as resumable summaries: goal, selected slice, scope, non-goals, decisions, trade-offs, open questions, behavior or delta design, test matrix or verification plan, implementation slices, and approval evidence. Do not store private chain-of-thought.

If the target project is missing `docs/_templates/task-goal.md`, `docs/_templates/task-diagram.md`, or `docs/_templates/task-memories.md`, that is a documentation gap, not permission to skip task memory. Use the installed Compass templates from `assets/docs-seed/_templates/` or the structure in `references/task-memory.xml`, create the required task files, and report the missing target templates.

Update task memory whenever a slice starts, completes, becomes blocked, changes, or whenever the goal changes. If slices change but the goal remains stable, update the same task folder. If the goal changes, create a new task folder, mark the old goal `superseded`, cross-link both goals, and record the reason in both memory histories.

Task templates belong to the project; the Compass templates are samples. A project may add, reorder, or rename sections, but every task file must keep the Compass-required headings listed under `required-headings` in `references/task-memory.xml`, matched case-insensitively.

Keep task memory cheap to resume. `goal.md` holds current state only: goal, scope, non-goals, success criteria, the slice table, and one Latest Evidence entry that is replaced at each slice instead of appended. Record per-slice evidence in a `memories.md` `HISTORIES` entry, and move durable research findings to `docs/modules/` or a decision record. Rewrite `SUMMARIES` at each checkpoint instead of appending, keeping it near 40 lines; everything from `SUMMARIES` to the next heading defined by the project template is read on resume, so do not park detail sections there. `scripts/docs-index.sh --tasks` warns when a Compass-required heading is missing, when `goal.md` exceeds 120 lines, or when that summary region exceeds 60 lines.

Longer material, such as an API contract, a JSON schema, a YAML contract, fixtures, or detailed notes, goes into supporting files in the task folder with no line limit. List each supporting file in the `goal.md` References section with when to read it, read it only when the current slice needs it, and when the goal completes, move files that stay the source of truth after the task to the project's durable location. `scripts/docs-index.sh --tasks` warns about supporting files that `goal.md` or `memories.md` does not link.

When a goal is completed, superseded, or cancelled, run close-out as defined in `references/task-memory.xml`: harvest its durable knowledge into permanent docs with developer approval, remove links from permanent docs into its folder, record the summary in the commit or merge request, then delete the folder with approval. Task memory is temporary, so permanent docs must not link into docs/.tasks; task memory may link to docs. Task memory is committed by default; ignore `docs/.tasks` only for a stated reason recorded in the project docs.

Use these goal statuses only: `active`, `completed`, `superseded`, and `cancelled`.

Use these slice statuses only: `pending`, `active`, `done`, and `blocked`.

The `memories.md` file may include a rationale snapshot for `LLM memikirkan`, but it must not expose private chain-of-thought. Record assumptions, trade-offs, risks, and reasons that help a future agent resume safely.

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
2. Run the Session Update Gate once per Codex session before any project bootstrap, classification, planning, or implementation.
3. Check missing seed docs and orientation lock. If docs are missing, offer preset choices before bootstrapping; do not auto-run bootstrap.
4. If bootstrap just ran, adapt copied preset docs to the target language or stack before treating docs as ready.
5. Build the project docs context from `docs/` using the Project Docs Integration rules: read the orientation lock and workflows, then select the remaining docs from `scripts/docs-index.sh` output.
6. Classify the task using `references/classification.xml`.
7. Load the matching task definition from `references/task-types.xml`.
8. Load the matching workflow from project `docs/process/workflows.xml`. If the file or matching workflow type is missing, do not use a fallback workflow; seed, migrate, or adapt Compass docs first.
9. Load `references/bootstrap-rules.xml` when docs or orientation lock need to be seeded.
10. Load `references/documentation-policy.xml` when creating or changing documentation.
11. Tell the user the task type, why it fits, and the workflow you will follow using the XML response shape below.
12. Execute only the next allowed phase. If a phase has an approval gate, stop at that gate and wait for explicit approval before continuing.
13. Before implementation starts, run the Task Memory Gate. If gated design context must be preserved, or long/risky work has at least two concrete slices after align-context, fit-design, or the approved design phase, inspect or create task memory using `references/task-memory.xml`. Report `created`, `resumed`, or `not-required` with the folder path or reason.
14. If implementation is requested, continue only after all earlier gated phases have explicit developer approval, then verify with the task's completion evidence.

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
- Implementation may start only after the Task Memory Gate has been reported. For required task memory, `docs/.tasks/<task>/goal.md`, `diagram.md`, and `memories.md` must exist before the first implementation edit or command.
- Missing task memory templates in the target project do not waive the gate; use the installed Compass templates or `references/task-memory.xml`, then report the project-doc gap.
- Implementation must run as small manual checkpoints. Implement exactly one approved slice, run the relevant verification, stop, report what changed and what passed or failed, then ask the developer before continuing to the next slice.
- Medium or high-risk `feature_update` work must protect the baseline before editing: identify current behavior, contracts, tests, owner, risk level, and unchanged behavior before delta design.
- `feature_update` implementation may start only after the approved delta is explicit: old behavior, new behavior, unchanged behavior, regression evidence, slice plan, docs impact, and rollout or cleanup risk.
- Feature flags, dark launches, compatibility paths, or rollback controls introduced by a `feature_update` must have cleanup or follow-up evidence before the update is called complete.
- Live Environment Gate: before any command that mutates a live environment, such as apply, deploy, restart, delete, scale, a secret write, or a console change, show plan or dry-run evidence for that exact change, state the rollback plan, and get explicit developer approval for that command.
- After a live change, verify the resulting live state; re-reading command output is not verification. Record what changed and how it was verified.
- During `hotfix_incident`, phase order may be shortened, but approval before each mutating command still applies, and any break-glass change is recorded immediately after. Risk tiers, approval depth, and tool commands come from the project's workflow or preset; the Live Environment Gate is the Compass minimum.
- Do not stop, remove, or prune containers, volumes, images, or networks that the agent did not start in this task without explicit developer approval; they may belong to other projects.
- A general request such as "build feature Y" or "implement Z" is not approval to skip brainstorming and design. Treat it as the start of the `new_feature` workflow.
- If the user explicitly says to skip a phase, state the skipped gate and risk before continuing.

## Routing Rules

- Prefer the task type that controls risk, not the label the user used.
- Treat an existing module, feature folder, screen, or component as placement evidence only. Adding a new use case or capability inside it is still `new_feature`, not `feature_update`.
- Use `feature_update` only when an already-existing use case, rule, contract, or user flow is intentionally changed.
- If a task touches architecture boundaries, classify it as `architecture_change` even when it also adds behavior.
- If a task changes database schema, include `db_migration` as a secondary type even when the primary type is `new_feature`, `feature_update`, or `bug_fix`.
- If a task mutates a live environment, include `infra_change` as a secondary type even when the primary type is `new_feature`, `bug_fix`, `release_deploy`, or `hotfix_incident`.
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
  <documentation-context>docs loaded with a one-line reason each, docs missing, index warnings, or none found</documentation-context>
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

# Compass

Compass is an engineering workflow skill for software projects. It helps an agent classify a request, select the appropriate workflow, enforce risk-based gates, and seed durable project documentation when a project does not yet have a reliable knowledge structure.

The purpose of Compass is simple: before changing files, the agent should understand what kind of work it is doing, what evidence is required, and which decisions must be made explicit. This reduces accidental scope growth, weak implementation plans, undocumented architecture changes, and code changes that are difficult to verify.

## Why Use Compass

Software work often fails for ordinary reasons: a feature starts before the behavior is clear, a bug fix becomes a refactor, a refactor silently changes behavior, or an architecture decision is made inside code without being recorded anywhere. Compass exists to prevent those mistakes by turning each request into a classified engineering task with an explicit workflow.

Use Compass when you want an agent to behave less like a text generator and more like a disciplined engineering partner. It makes the agent pause at the right moments, ask for approval when the risk requires it, and produce evidence before claiming the work is complete.

Compass is especially valuable when:

- a request may contain more than one feature or change;
- the task could affect architecture, module boundaries, database ownership, or cross-module contracts;
- the repository does not yet have clear engineering documentation;
- the team wants consistent handling for features, fixes, refactors, tests, tooling, releases, security work, and incidents;
- the agent must explain why a workflow was chosen before implementation begins;
- implementation should proceed in small, verified checkpoints instead of one large uncontrolled change.

In short, Compass keeps the work pointed in the right direction. Without it, an agent may run quickly in the wrong direction. That is still movement, but it is not progress.

## What Compass Does

Compass provides four main capabilities.

### 1. Task Classification

Compass classifies engineering requests by risk and required evidence, not merely by the user's wording. The classification reference supports task types such as:

- `new_feature`
- `feature_update`
- `bug_fix`
- `hotfix_incident`
- `refactor`
- `architecture_change`
- `performance`
- `security`
- `db_migration`
- `dependency_update`
- `build_ci_tooling`
- `docs_only`
- `test_only`
- `cleanup_chore`
- `research_spike`
- `release_deploy`

This classification matters because different kinds of work require different proof. A production incident should not be handled like a normal backlog bug. A refactor must prove behavior did not change. A database migration must account for ownership, rollback or forward-fix expectations, and schema assumptions. Compass makes those distinctions explicit.

### 2. Workflow Routing

After classification, Compass selects the matching workflow from `references/workflows.xml`. Each workflow defines the ordered steps and completion evidence for the task type.

For example:

- bug fixes require reproduction, minimization, root-cause analysis, a regression test, and targeted verification;
- refactors require unchanged behavior to be defined and protected before structural changes begin;
- architecture changes require boundary changes and trade-offs to be stated, with documentation updated before or alongside code;
- performance work requires a baseline, bottleneck evidence, and before-after comparison;
- security work requires the affected asset, threat, vulnerable path, and sensitive-data handling to be considered.

This prevents the agent from treating all tasks as the same kind of implementation problem.

### 3. Gates For High-Risk Work

Compass applies hard gates to new feature work. A `new_feature` workflow has three sequential phases:

1. Brainstorming
2. Design
3. Implementation

Brainstorming and design are planning-only phases. They must not edit files, create tests, apply patches, or run implementation commands, except for the first-run documentation bootstrap. The agent must stop after brainstorming and ask whether to challenge the shared understanding or continue to design. It must stop again after design and ask whether to adjust behavior or continue to implementation.

Implementation may begin only after the design is explicitly approved. Once implementation starts, Compass requires small manual checkpoints: implement one approved slice, run the relevant verification, report the result, and wait before continuing.

These gates are intentionally strict. They protect the project from the common mistake of treating "build feature X" as permission to skip understanding, design, behavior selection, and verification.

### 4. Documentation Bootstrap

Compass can seed a project with a durable documentation structure under `docs/`. The bootstrap script creates missing seed documents without overwriting existing files unless force mode is explicitly used.

The seed documentation includes:

- project documentation entry points;
- engineering philosophy;
- architecture principles;
- documentation principles;
- testing principles;
- implementation workflow;
- architecture, decisions, modules, process, runbooks, and reference hubs;
- reusable templates for decision records and module notes.

This gives projects a clear knowledge architecture before the codebase becomes a maze. Documentation is treated as part of engineering design, not as a decorative appendix written after the important decisions have already disappeared into commit history.

## Implementing High-Level Engineering Principles

Compass makes broad engineering principles practical because it turns them into workflow constraints, review questions, and required evidence. Principles such as SOLID, Clean Architecture, TDD, boundary ownership, incremental delivery, documentation discipline, and risk-based verification are often easy to admire but hard to apply consistently. Compass closes that gap by deciding when those principles matter and where they must appear in the work.

For example, a team may say it wants to use SOLID. Without a workflow, that statement can become vague advice applied only during code review. With Compass, SOLID becomes part of the task route:

- Single Responsibility is reinforced by classifying the task clearly and keeping each implementation slice focused on one reason to change.
- Open/Closed is supported by designing behavior and contracts before implementation, so stable behavior can grow without rewriting unrelated areas.
- Liskov Substitution is protected by behavior tests that define consumer expectations before implementations are swapped or extended.
- Interface Segregation is encouraged by consumer-owned ports and narrow contracts instead of broad provider-owned abstractions.
- Dependency Inversion is enforced by keeping stable policy inward and pushing frameworks, persistence, delivery, queues, and external services toward adapters.

The same pattern applies to Clean Architecture. Compass does not merely tell the agent to "use clean architecture." It asks the agent to identify boundaries, dependency direction, core behavior, application orchestration, adapters, and platform concerns. It also treats architecture changes as a separate risk category, requiring explicit trade-offs, documentation updates, and verification. This makes architectural discipline observable instead of decorative.

TDD also becomes easier to apply because Compass places it inside the right phase. A new feature cannot jump straight into tests and code. It must first pass through brainstorming and design, where the behavior-test matrix is selected and ordered from common paths to edge cases. During implementation, each slice can then follow the test-first loop with a clear target behavior. The agent is not writing tests in the dark; it is proving an approved behavior.

Other high-level development practices fit naturally into the same model:

- Domain-driven thinking becomes clearer because Compass asks which rules, invariants, entities, value objects, and policies belong to the core.
- Incremental delivery becomes safer because implementation proceeds through small verified slices.
- Documentation-as-design becomes practical because boundary and workflow changes must update durable docs, not only code.
- Risk-based testing becomes concrete because every task type defines the evidence needed to complete the work.
- Refactoring discipline improves because refactors must preserve behavior and must not smuggle in feature changes.
- Operational maturity improves because incidents, releases, security work, and performance work each have their own workflow instead of sharing one generic implementation path.

This is why Compass is useful for senior engineering standards. It does not replace judgment. It gives judgment a repeatable shape, so the same principles can be applied under pressure, across projects, and by different agents or developers.

## Token Efficiency

Compass is also more token-efficient than an unstructured "read the PRD and implement everything" approach. A raw PRD often pushes an agent to read broadly, infer hidden priorities, design too much at once, and produce a large implementation in one pass. That usually creates more backtracking, larger diffs, repeated explanations, and longer repair loops.

A Compass-guided workflow saves tokens by narrowing the problem early:

- classification tells the agent which workflow applies instead of making every task look like a full feature build;
- documentation bootstrap gives the agent stable project principles to reference instead of rediscovering the same assumptions repeatedly;
- gates stop the agent before it spends context on implementation that has not been approved;
- a behavior-test matrix limits implementation to selected behavior instead of all possible interpretations of the PRD;
- small slices reduce the amount of code, context, and verification that must be reasoned about at once;
- completion evidence prevents long speculative summaries by focusing on what changed and what passed.

The important point is not that Compass uses fewer words in every single response. The important point is that it spends tokens on decisions that reduce later waste. A developer or agent that follows a workflow usually spends fewer total tokens than one that charges through a PRD, implements too broadly, then spends several rounds explaining, undoing, and repairing the result. Like measuring rice before cooking, it feels slower for five seconds and saves dinner from becoming porridge.

## Goal And Grill Versus PRD To Implementation

The `new_feature` workflow uses a goal-and-grill style before implementation: first establish the goal, then challenge the understanding, then design behavior, then implement one approved slice. This is more effective than a simple `plan or PRD -> implement` path because PRDs are rarely complete enough to be executable specifications.

A PRD is useful, but it often mixes goals, constraints, assumptions, examples, and open questions. If an agent implements directly from it, the agent must silently choose interpretations. Those silent choices become hidden product decisions inside code.

Goal-and-grill makes those choices visible before code exists:

- the goal is restated in user-facing or API-facing terms;
- target users, success criteria, constraints, and visible failure states are made explicit;
- multiple features are split into feature slices instead of being merged into one large change;
- unclear behavior is challenged before implementation creates sunk cost;
- suggested behavior is marked as selected, rejected, or postponed;
- implementation begins only after the design has explicit approval.

This produces better engineering outcomes because the project receives both alignment and evidence. The agent does not merely "follow the PRD"; it tests whether the PRD is clear enough to build. When it is not clear, the workflow exposes the ambiguity while it is still cheap to fix.

The practical difference is this:

- `plan or PRD -> implement` optimizes for starting quickly.
- `goal -> grill -> design -> approved slice -> verify` optimizes for finishing correctly.

Starting quickly is pleasant. Finishing correctly is what keeps maintainers from looking at yesterday's code like it owes them money.

## Repository Structure

```text
.
|-- SKILL.md
|-- agents/
|   `-- openai.yaml
|-- assets/
|   `-- docs-seed/
|-- references/
|   |-- bootstrap-rules.xml
|   |-- classification.xml
|   |-- documentation-policy.xml
|   |-- task-types.xml
|   `-- workflows.xml
`-- scripts/
    `-- bootstrap-docs.sh
```

### `SKILL.md`

The main skill entry point. It explains when Compass should be used, how a Compass-guided task starts, the hard gates for feature work, the routing rules, and the expected response shape for planning or triage.

### `references/classification.xml`

The decision tree for classifying work. It prioritizes production impact, investigation, architecture, database changes, behavior changes, defects, security, tooling, documentation, tests, chores, and releases.

### `references/task-types.xml`

The supported task taxonomy. It maps each task type to common labels, usage conditions, and Conventional Commit hints.

### `references/workflows.xml`

The workflow checklist for each task type. This is the operational core of Compass: it defines required steps, gates, phase outputs, and evidence expectations.

### `references/bootstrap-rules.xml`

The rules for seeding project documentation. It defines when bootstrap should run, which files are expected, and what completion evidence should be reported.

### `references/documentation-policy.xml`

The documentation governance model. It protects projects from competing sources of truth by defining document categories, status values, and placement rules.

### `assets/docs-seed/`

The source templates copied into a target project's `docs/` directory by the bootstrap script.

### `scripts/bootstrap-docs.sh`

The idempotent script used to create missing seed documentation.

## Usage

When Compass is installed as an agent skill, ask the agent to use Compass for engineering work. A typical request can be as simple as:

```text
Use Compass to classify this task and tell me the workflow before editing files.
```

Compass should then produce a routing response similar to:

```xml
<task-routing>
  <primary-type>bug_fix</primary-type>
  <secondary-type>none</secondary-type>
  <why>The request restores expected behavior after a defect.</why>
  <workflow>
    <step>Reproduce or gather evidence for the bug.</step>
    <step>Minimize the failing scenario.</step>
    <step>Identify root cause before editing.</step>
    <step>Add a failing regression test.</step>
    <step>Fix the smallest cause.</step>
    <step>Run targeted tests, then broader tests if risk warrants.</step>
  </workflow>
  <evidence>Reproduction, regression test, and passing verification.</evidence>
  <commit-hint>fix</commit-hint>
</task-routing>
```

For a first run in a project that needs seed documentation, use the bootstrap script. From this repository, run:

```bash
./scripts/bootstrap-docs.sh --target /path/to/project
```

When Compass is installed inside a project at `.skills/compass`, the skill refers to:

```bash
.skills/compass/scripts/bootstrap-docs.sh --target .
```

Use `--dry-run` to preview actions:

```bash
./scripts/bootstrap-docs.sh --target /path/to/project --dry-run
```

Use `--force` only when existing documentation should be overwritten intentionally:

```bash
./scripts/bootstrap-docs.sh --target /path/to/project --force
```

## When To Use Compass

Use Compass for normal software engineering work, including:

- planning a new feature;
- updating existing behavior;
- fixing bugs;
- handling incidents or hotfixes;
- refactoring safely;
- changing architecture boundaries;
- changing database schema or persistence ownership;
- improving performance;
- addressing security issues;
- updating dependencies;
- modifying build, CI, or tooling;
- creating or reorganizing documentation;
- adding tests or test infrastructure;
- preparing a release or deployment.

Compass is not limited to one programming language, framework, or architecture style. It deliberately avoids language-specific best practices. Project-specific and stack-specific details should come from the repository being worked on.

## When Not To Use Compass

Compass is unnecessary for tasks that are not software engineering work, such as general writing, casual Q&A, or unrelated research. It may also be too heavy for a tiny one-line command where no classification, workflow, documentation, or verification decision is needed.

However, if a small request could alter behavior, architecture, security, data, or release state, Compass is still appropriate. Small changes can carry large consequences; a small key can open a large door.

## Design Principles

Compass is built around several engineering principles:

- classify by risk, not by labels;
- protect high-risk work with explicit gates;
- keep one feature cycle focused on one feature;
- design behavior before implementation;
- use the cheapest meaningful evidence;
- document durable decisions where future maintainers will look for them;
- avoid abstractions, files, and workflows that do not yet have a real reason to exist.

These principles make Compass useful for both humans and agents. Humans get a clearer explanation of the work. Agents get a narrower path with fewer opportunities to improvise badly.

## Expected Outcome

A Compass-guided task should leave behind more than changed files. It should leave behind:

- a clear task classification;
- an explicit workflow;
- documented approval gates where needed;
- implementation slices that are small enough to review;
- verification evidence appropriate to the risk;
- documentation updates when boundaries, contracts, or project knowledge change.

That is the practical value of Compass: it converts vague engineering intent into a controlled sequence of decisions, actions, and evidence.

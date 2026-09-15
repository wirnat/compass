---
type: foundation
status: active
owner: engineering
created: 2026-09-15
updated: 2026-09-15
parent: "[[docs/foundation/README]]"
summary: Principles for changing live infrastructure safely, from declared state as source of truth to verifying the live result.
tags:
  - docs/foundation
  - status/active
aliases:
  - operations principles
  - ops principles
related:
  - "[[docs/architecture/infrastructure-layout]]"
  - "[[docs/process/change-workflow]]"
---

# Operations Principles

These principles decide how this repository changes live environments. When a shortcut conflicts with one of them, the principle wins unless a decision record says otherwise.

## Principles

1. **Declared state is the source of truth.** What should exist is written in this repository. The live environment is expected to match it.
2. **Change through the repository.** Console or CLI changes are break-glass only, during an incident, and are recorded immediately.
3. **Plan before apply.** Read the plan or dry-run before running the change. Destroy and replace counts are read first.
4. **Small, reversible changes.** One concern per change, with a rollback plan sized to its risk tier.
5. **Idempotent and repeatable.** Applying the same declared state twice gives the same result.
6. **Verify the live result, not the command output.** A successful apply only says the tool finished. Check that the thing works.
7. **Drift is a finding.** When live state differs from declared state, record the difference before reconciling it.
8. **Least privilege.** Humans, pipelines, and agents get only the access the change needs.
9. **Blast radius first.** Before changing something, know what else fails if it fails.
10. **Secrets stay out of plaintext.** Record which secrets a change reads or writes.

## Anti-Patterns

- Fixing production in the console and never writing it back to declared state.
- Treating a green pipeline as proof that the service works.
- Reconciling drift silently, so nobody learns why it happened.
- Bundling unrelated environments into one apply.

Kalau server diubah lewat console tanpa dicatat, repo ini berubah jadi dongeng: semua percaya, tidak ada yang bisa membuktikan.

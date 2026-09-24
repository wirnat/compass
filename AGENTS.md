# AGENTS.md

Rules for any agent (Qoder, Claude Code, Cursor, Copilot, or other) working in
this repository.

## Compass dogfooding is mandatory

This repo uses its own Compass workflow. Working ON the discipline tool does
not exempt the work FROM the discipline.

- Classify the task against `docs/process/workflows.xml` and read
  `docs/decisions/0001-orientation-lock.md` before the first file edit.
- Run `scripts/docs-index.sh --target . --match <keywords>` to select relevant
  docs instead of opening notes one by one.
- Run `scripts/docs-index.sh --tasks` to check open goals. `docs/.tasks/` is
  gitignored (this is a public repo), so task memory is machine-local —
  resume the matching goal if one exists; do not create a duplicate.
- Append a HISTORIES entry to `memories.md` as each slice completes. Never
  write history retroactively at close-out.
- When a goal finishes, run close-out in the same session: harvest durable
  knowledge, remove links into the folder, and ask developer approval before
  deleting it — deletion is irreversible because `docs/.tasks/` is gitignored.
- User approval of a plan ("go ahead", "do it") is not a substitute for gate
  bookkeeping. Report classification and gate outcomes before implementing.

Reason: on 2026-09-24 an agent implemented `docs-index.sh --match` in this
repo and skipped every gate above; the developer had to point out the still
open task. The code was correct; the discipline records were not.

## scripts/docs-index.sh formatting pitfalls

- The `  - ` prefix and YAML quoting of warning lines are emitted by the awk
  programs (the `W` line and `link_prog`), not by bash. Re-adding prefixes at
  the bash layer produces double prefixes.
- `entries` and `warnings` are accumulator strings. Do not convert them to
  arrays when adding post-processing (e.g. the `--match` filter); filter with
  a standalone awk pass over the final string.
- Command substitution strips trailing newlines. After filtering `entries`,
  restore one (`entries+=$'\n'`), or the next top-level key (`skipped:`)
  glues onto the last entry line.

Reason: both defects were hit while adding `--match` and cost long debug
cycles because the format-owning layer (awk) was not read first.

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
INDEX="$ROOT_DIR/scripts/docs-index.sh"
BOOTSTRAP="$ROOT_DIR/scripts/bootstrap-docs.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/compass-docs-index.XXXXXX")"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  rm -rf "$TMP_ROOT"
}

require_line() {
  local output="$1"
  local line="$2"
  local label="$3"

  printf '%s\n' "$output" | grep -Fxq -- "$line" || fail "$label: missing output line: $line"
}

reject_text() {
  local output="$1"
  local text="$2"
  local label="$3"

  if printf '%s\n' "$output" | grep -Fq -- "$text"; then
    fail "$label: unexpected output text: $text"
  fi
}

write_file() {
  mkdir -p "$(dirname "$1")"
  cat > "$1"
}

repeat_lines() {
  local i=0

  while [ "$i" -lt "$1" ]; do
    printf '%s\n' "$2"
    i=$((i + 1))
  done
}

trap cleanup EXIT

[ -x "$INDEX" ] || fail 'missing executable script: scripts/docs-index.sh'

# Every bootstrapped preset doc is indexed exactly once, without warnings.
for preset_dir in "$ROOT_DIR"/assets/orientation-presets/*/; do
  preset="$(basename "$preset_dir")"
  target="$TMP_ROOT/$preset"
  "$BOOTSTRAP" --target "$target" --preset "$preset" >/dev/null
  output="$("$INDEX" --target "$target")"
  expected="$(cd "$target" && find docs -name '*.md' -not -path 'docs/_templates/*' | LC_ALL=C sort)"
  actual="$(printf '%s\n' "$output" | sed -n 's/^  - path: "\(.*\)"$/\1/p')"
  [ "$expected" = "$actual" ] || fail "$preset: indexed paths differ from docs on disk"
  require_line "$output" 'skipped: 0' "$preset"
  reject_text "$output" 'warnings:' "$preset"
done

fixture="$TMP_ROOT/fixture"
mkdir -p "$fixture/src/packing"
: > "$fixture/src/packing/pack.go"

write_file "$fixture/docs/modules/packing.md" <<'EOF'
---
type: module
status: active
summary: Packing "station": label #1
aliases:
  - packing
  - label
related:
  - "[[docs/decisions/0002-old]]"
code:
  - src/packing/**
---

# Packing Module
EOF

write_file "$fixture/docs/modules/billing.md" <<'EOF'
---
type: module
status: draft
aliases: [billing, invoice]
code: [src/billing/**]
---

# Billing Module
EOF

write_file "$fixture/docs/notes.md" <<'EOF'
# Loose Notes
EOF

write_file "$fixture/docs/plain.md" <<'EOF'
No heading here.
EOF

write_file "$fixture/docs/decisions/0002-old.md" <<'EOF'
---
type: decision
status: superseded
---

# 0002 Old Decision
EOF

write_file "$fixture/docs/decisions/0003-archived.md" <<'EOF'
---
type: decision
status: archived
---

# 0003 Archived Decision
EOF

write_file "$fixture/docs/_templates/module-note.md" <<'EOF'
---
type: module
---

# Template
EOF

write_file "$fixture/docs/.tasks/20260101-0000_x/goal.md" <<'EOF'
# Task Goal
EOF

output="$("$INDEX" --target "$fixture")"

require_line "$output" '  - path: "docs/modules/packing.md"' 'fixture'
require_line "$output" '    summary: "Packing \"station\": label #1"' 'summary field wins and is escaped'
require_line "$output" '    aliases: ["packing", "label"]' 'block list'
require_line "$output" '    related: ["docs/decisions/0002-old.md"]' 'wikilink related'
require_line "$output" '    code: ["src/packing/**"]' 'code field'
require_line "$output" '    summary: "Billing Module"' 'H1 fallback'
require_line "$output" '    aliases: ["billing", "invoice"]' 'inline list'
require_line "$output" '    summary: "plain"' 'filename fallback'
require_line "$output" 'skipped: 2' 'superseded and archived skipped'
require_line "$output" '  - "docs/modules/billing.md: code glob matches no files: src/billing/**"' 'unmatched code glob warning'
reject_text "$output" 'docs/modules/packing.md: code glob' 'matched code glob'
reject_text "$output" '  - path: "docs/decisions/' 'default status filter'
reject_text "$output" '_templates' 'templates excluded'
reject_text "$output" '.tasks' 'hidden folders excluded'

notes_block="$(printf '%s\n' "$output" | awk '/^[^ ]/{p=0} /^  - path: /{p=($0=="  - path: \"docs/notes.md\"")} p')"
[ "$notes_block" = '  - path: "docs/notes.md"
    summary: "Loose Notes"' ] || fail "doc without frontmatter should list only path and H1 summary, got: $notes_block"

all_output="$("$INDEX" --target "$fixture" --all)"
require_line "$all_output" '  - path: "docs/decisions/0002-old.md"' '--all includes superseded'
require_line "$all_output" '  - path: "docs/decisions/0003-archived.md"' '--all includes archived'
require_line "$all_output" 'skipped: 0' '--all skips nothing'

code=0
"$INDEX" --target "$TMP_ROOT/missing" >/dev/null 2>"$TMP_ROOT/err" || code=$?
[ "$code" -eq 1 ] || fail "missing docs directory should exit 1, got $code"
grep -Fq 'docs directory not found' "$TMP_ROOT/err" || fail 'missing docs directory message'

code=0
"$INDEX" --target >/dev/null 2>&1 || code=$?
[ "$code" -eq 2 ] || fail "--target without value should exit 2, got $code"

# --tasks lists open task memory goals and warns about structure drift.
tasks="$TMP_ROOT/tasks"
# Compass-required headings from references/task-memory.xml.
goal_body='## Non-Goals\n\n## Success Criteria\n\n## Slices\n\n## Latest Evidence\n\n## Goal Links\n'
diagram_body='# Diagram\n\n## How To Read\n\n## Text Checkpoints\n'

# Args: folder name, goal_status ("" omits it), goal.md line count (0 keeps the
# natural size), SUMMARIES body line count.
make_task() {
  local dir="$tasks/docs/.tasks/$1"

  mkdir -p "$dir"
  {
    printf -- '---\ntype: task-goal\nupdated: "2026-09-10 10:00 +08:00"\n'
    if [ -n "$2" ]; then
      printf 'goal_status: %s\n' "$2"
    fi
    printf -- '---\n\n# Goal %s\n' "$1"
    printf "$goal_body"
  } > "$dir/goal.md"
  repeat_lines $(( $3 - $(wc -l < "$dir/goal.md") )) 'filler' >> "$dir/goal.md"
  printf "$diagram_body" > "$dir/diagram.md"
  {
    printf '# Memories\n\n## SUMMARIES\n'
    repeat_lines "$4" 'summary line'
    printf '## HISTORIES\n\n[2026-09-10 10:00 +08:00]\n'
  } > "$dir/memories.md"
}

make_task 20260901-1000_valid-active active 0 5
make_task 20260801-1000_done-goal completed 0 5
make_task 20260802-1000_superseded-goal superseded 0 5
make_task 20260803-1000_cancelled-goal cancelled 0 5
make_task 20260804-1000_memories-only active 0 5
rm "$tasks/docs/.tasks/20260804-1000_memories-only/goal.md" "$tasks/docs/.tasks/20260804-1000_memories-only/diagram.md"
make_task 20260805-1000_open-status open 0 5
make_task 20260806-1000_no-status '' 0 5
make_task 20260807-1000_freeform-memories active 0 5
printf '# Memories\n\n## History\n' > "$tasks/docs/.tasks/20260807-1000_freeform-memories/memories.md"
make_task 20260808-1000_big-goal active 121 5
make_task 20260809-1000_at-limit active 120 60
make_task 20260810-1000_long-summaries active 0 61
make_task ai-receptionist-g0 active 0 5
make_task 20260811-1000_extra-sections active 0 5
{
  printf '# Memories\n\n## SUMMARIES\nshort summary\n## Extra Detail\n'
  repeat_lines 60 'detail line'
  printf '## HISTORIES\n'
} > "$tasks/docs/.tasks/20260811-1000_extra-sections/memories.md"
make_task 20260812-1000_goal-without-core active 0 5
printf -- '---\ngoal_status: active\n---\n\n# Goal\n\n## Slices\n' > "$tasks/docs/.tasks/20260812-1000_goal-without-core/goal.md"
printf '# Diagram\n\n## How To Read\n' > "$tasks/docs/.tasks/20260812-1000_goal-without-core/diagram.md"
make_task 20260813-1000_title-case active 0 5
{
  printf '# Memories\n\n## Summaries\n'
  repeat_lines 61 'summary line'
  printf '## Histories\n'
} > "$tasks/docs/.tasks/20260813-1000_title-case/memories.md"

tasks_output="$("$INDEX" --target "$tasks" --tasks)"

require_line "$tasks_output" '  - folder: "docs/.tasks/20260901-1000_valid-active"' 'tasks listing'
require_line "$tasks_output" '    goal_status: "active"' 'tasks goal_status'
require_line "$tasks_output" '    updated: "2026-09-10 10:00 +08:00"' 'tasks updated'
require_line "$tasks_output" '    title: "Goal 20260901-1000_valid-active"' 'tasks title'
require_line "$tasks_output" 'skipped: 3' 'closed goals skipped'
require_line "$tasks_output" '  - folder: "docs/.tasks/20260804-1000_memories-only"' 'folder without goal.md stays visible'
require_line "$tasks_output" '  - "docs/.tasks/20260804-1000_memories-only: missing goal.md, diagram.md"' 'missing files warning'
require_line "$tasks_output" '  - "docs/.tasks/20260805-1000_open-status: invalid goal_status: open"' 'invalid status warning'
require_line "$tasks_output" '  - "docs/.tasks/20260806-1000_no-status: missing goal_status"' 'missing status warning'
require_line "$tasks_output" '  - "docs/.tasks/20260807-1000_freeform-memories: memories.md lacks required headings: ## SUMMARIES, ## HISTORIES"' 'memories heading warning'
require_line "$tasks_output" '  - "docs/.tasks/20260808-1000_big-goal: goal.md has 121 lines (limit 120)"' 'goal size warning'
require_line "$tasks_output" '  - "docs/.tasks/20260810-1000_long-summaries: memories.md SUMMARIES has 61 lines (limit 60)"' 'summaries size warning'
require_line "$tasks_output" '  - "docs/.tasks/20260811-1000_extra-sections: memories.md SUMMARIES has 62 lines (limit 60)"' 'extra sections before HISTORIES count toward SUMMARIES'
require_line "$tasks_output" '  - "docs/.tasks/20260812-1000_goal-without-core: goal.md lacks required headings: ## Non-Goals, ## Success Criteria, ## Latest Evidence, ## Goal Links"' 'Compass-required goal headings'
require_line "$tasks_output" '  - "docs/.tasks/20260812-1000_goal-without-core: diagram.md lacks required headings: ## Text Checkpoints"' 'Compass-required diagram headings'
require_line "$tasks_output" '  - "docs/.tasks/20260813-1000_title-case: memories.md SUMMARIES has 61 lines (limit 60)"' 'SUMMARIES heading matches case-insensitively'
reject_text "$tasks_output" '20260813-1000_title-case: memories.md lacks' 'title-case headings satisfy the standard'
require_line "$tasks_output" '  - "docs/.tasks/ai-receptionist-g0: folder name is not YYYYMMDD-HHMM_slug"' 'folder name warning'
reject_text "$tasks_output" '20260801-1000_done-goal' 'completed goal hidden by default'
reject_text "$tasks_output" '20260802-1000_superseded-goal' 'superseded goal hidden by default'
reject_text "$tasks_output" '20260803-1000_cancelled-goal' 'cancelled goal hidden by default'
reject_text "$tasks_output" '20260809-1000_at-limit:' 'size limits are inclusive'
reject_text "$tasks_output" '20260901-1000_valid-active:' 'valid goal has no warnings'
reject_text "$tasks_output" 'docs:' 'tasks mode lists no docs'

all_tasks="$("$INDEX" --target "$tasks" --tasks --all)"
require_line "$all_tasks" '  - folder: "docs/.tasks/20260801-1000_done-goal"' '--tasks --all includes closed goals'
require_line "$all_tasks" 'skipped: 0' '--tasks --all skips nothing'

no_tasks="$("$INDEX" --target "$TMP_ROOT/clean-solid-tdd" --tasks)"
require_line "$no_tasks" 'tasks: []' 'project without docs/.tasks'
require_line "$no_tasks" 'skipped: 0' 'project without docs/.tasks skips nothing'

# Projects own their task templates: only Compass-required headings are enforced,
# and project template headings only end the SUMMARIES region.
# Args: project dir, task folder name; memories.md content comes from stdin.
write_task_files() {
  local dir="$1/docs/.tasks/$2"

  mkdir -p "$dir"
  printf -- '---\ngoal_status: active\n---\n\n# Goal %s\n' "$2" > "$dir/goal.md"
  printf "$goal_body" >> "$dir/goal.md"
  printf "$diagram_body" > "$dir/diagram.md"
  cat > "$dir/memories.md"
}

custom="$TMP_ROOT/custom-tasks"
printf '# {{goal_name}} Memories\n\n## SUMMARIES\n\n## VERIFIED FACTS\n\n## HISTORIES\n' \
  | write_file "$custom/docs/_templates/task-memories.md"

{
  printf '## SUMMARIES\n'
  repeat_lines 5 'summary line'
  printf '## VERIFIED FACTS\n'
  repeat_lines 70 'fact line'
  printf '## HISTORIES\n'
} | write_task_files "$custom" 20260901-1000_designed-sections

printf '## SUMMARIES\nsummary line\n## HISTORIES\n' | write_task_files "$custom" 20260902-1000_missing-designed

{
  printf '## SUMMARIES\n'
  repeat_lines 5 'summary line'
  printf '## Agent Notes\n'
  repeat_lines 60 'note line'
  printf '## VERIFIED FACTS\nfact line\n## HISTORIES\n'
} | write_task_files "$custom" 20260903-1000_agent-extra

custom_output="$("$INDEX" --target "$custom" --tasks)"
reject_text "$custom_output" '20260901-1000_designed-sections:' 'sections defined by the project template are not summary bloat'
reject_text "$custom_output" '20260902-1000_missing-designed:' 'project template headings are not enforced'
require_line "$custom_output" '  - "docs/.tasks/20260903-1000_agent-extra: memories.md SUMMARIES has 66 lines (limit 60)"' 'sections outside the project template count toward SUMMARIES'

no_summary="$TMP_ROOT/no-summary-template"
printf '## Decision Log\n\n## Session Snapshot\n' | write_file "$no_summary/docs/_templates/task-memories.md"
{
  printf '## Decision Log\n'
  repeat_lines 100 'decision line'
} | write_task_files "$no_summary" 20260904-1000_long-log

no_summary_output="$("$INDEX" --target "$no_summary" --tasks)"
require_line "$no_summary_output" '  - "docs/.tasks/20260904-1000_long-log: memories.md lacks required headings: ## SUMMARIES, ## HISTORIES"' 'only Compass-required headings are enforced'
reject_text "$no_summary_output" 'SUMMARIES has' 'no summaries limit when the template has no SUMMARIES heading'

printf 'Docs index checks passed.\n'

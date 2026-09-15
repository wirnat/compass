#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_contains() {
  local path="$1"
  local needle="$2"
  local description="$3"

  grep -Fq "$needle" "$ROOT_DIR/$path" || fail "$path missing $description: $needle"
}

for path in SKILL.md README.md references/task-memory.xml; do
  require_contains "$path" 'created' 'task memory created outcome'
  require_contains "$path" 'resumed' 'task memory resumed outcome'
  require_contains "$path" 'not-required' 'task memory not-required outcome'
  require_contains "$path" 'gated design context' 'gated design context rule'
done

require_contains 'SKILL.md' 'approved implementation has only one slice' 'one-slice gated design context rule'
require_contains 'README.md' 'even when the approved implementation has one slice' 'one-slice gated design context rule'
require_contains 'references/task-memory.xml' 'even when the approved implementation has only one slice' 'one-slice gated design context rule'

for path in SKILL.md README.md docs/process/existing-process-lock.md; do
  require_contains "$path" 'npx skills update' 'skills CLI update path'
  require_contains "$path" 'scripts/update-skill.sh --skill-dir' 'fallback updater path'
done

while IFS= read -r -d '' workflow; do
  rel="${workflow#$ROOT_DIR/}"
  require_contains "$rel" 'created, resumed, or not-required' 'task memory outcomes'
  require_contains "$rel" 'gated design context' 'gated design context rule'
  require_contains "$rel" 'even if the approved implementation has one slice' 'one-slice gated design context rule'
done < <(find "$ROOT_DIR/assets/orientation-presets" -path '*/docs/process/workflows.xml' -print0)

while IFS= read -r stale; do
  [ -n "$stale" ] || continue
  if grep -R -Fq --exclude-dir='.git' --exclude-dir='.logs' --exclude='testing-strategy.md' "$stale" \
    "$ROOT_DIR/SKILL.md" "$ROOT_DIR/README.md" "$ROOT_DIR/references" \
    "$ROOT_DIR/docs" "$ROOT_DIR/assets"; then
    fail "stale policy phrase still present: $stale"
  fi
done <<'STALE_PHRASES'
Task memory is required only when both
only for long or risky multi-slice work
Activation uses both task-risk
researched-principles
researched-workflow
STALE_PHRASES

for path in SKILL.md README.md references/documentation-policy.xml; do
  require_contains "$path" 'scripts/docs-index.sh' 'docs index script'
done

for path in SKILL.md README.md references/task-memory.xml; do
  require_contains "$path" 'docs-index.sh --tasks' 'task memory index'
done

# The seed sample templates must carry every Compass-required task memory heading.
required_count=0
while IFS=$'\t' read -r file heading; do
  require_contains "assets/docs-seed/_templates/task-${file%.md}.md" "$heading" 'Compass-required task memory heading'
  required_count=$((required_count + 1))
done < <(awk -F'"' '/<heading file="/ { h = $0; sub(/.*">/, "", h); sub(/<\/heading>.*/, "", h); print $2 "\t" h }' "$ROOT_DIR/references/task-memory.xml")
[ "$required_count" -gt 0 ] || fail 'references/task-memory.xml lists no required task memory headings'

# Seed docs shipped to projects must match this repo's own bootstrapped copy.
# Hub READMEs listed below are intentionally customized for this repository.
while IFS= read -r -d '' seed; do
  rel="${seed#$ROOT_DIR/assets/docs-seed/}"
  case "$rel" in
    README.md|reference/README.md) continue ;;
  esac
  [ -f "$ROOT_DIR/docs/$rel" ] || continue
  cmp -s "$seed" "$ROOT_DIR/docs/$rel" || fail "assets/docs-seed/$rel and docs/$rel differ; update both copies"
done < <(find "$ROOT_DIR/assets/docs-seed" -type f -print0)

printf 'Policy consistency checks passed.\n'

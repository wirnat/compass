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

printf 'Docs index checks passed.\n'

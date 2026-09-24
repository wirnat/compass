#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
MEMORY_SYNC="$ROOT_DIR/scripts/memory-sync.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/compass-memory-sync.XXXXXX")"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

# --list-providers must work without a target.
"$MEMORY_SYNC" --list-providers | grep -qF 'claude-code' \
  || fail '--list-providers missing claude-code'
"$MEMORY_SYNC" --list-providers | grep -qF 'qoder' \
  || fail '--list-providers missing qoder'

# --help must work.
"$MEMORY_SYNC" --help | grep -qF 'memory-sync' \
  || fail '--help missing usage info'

# Unknown provider must fail.
if "$MEMORY_SYNC" --target "$TMP_ROOT" --provider unknown-provider 2>/dev/null; then
  fail 'unknown provider should have failed'
fi

# Simulate Claude Code memories and test import with classification.
target="$TMP_ROOT/test-project"
mkdir -p "$target/docs/.memory/shared" "$target/docs/.memory/local"

# Create fake Claude Code memory directory.
fake_claude="$TMP_ROOT/fake-claude-memory"
mkdir -p "$fake_claude"

# Shared memory: about architecture.
cat > "$fake_claude/arch-module.md" <<'EOF'
---
name: arch-module
description: "Auth module owns all JWT logic"
---

The auth module owns all JWT logic and token refresh. Other modules depend on
auth via the token interface, never directly on the JWT implementation.
EOF

# Local memory: about machine paths.
cat > "$fake_claude/local-go-path.md" <<'EOF'
---
name: local-go-path
description: "Go is installed at /usr/local/go"
---

Go is installed at /usr/local/go on my machine. GOPATH is ~/go.
EOF

# Ambiguous memory: no clear classification signals.
cat > "$fake_claude/something.md" <<'EOF'
---
name: something
description: "A note about something"
---

We discussed this in the meeting and decided to keep it simple.
EOF

# Test import from the fake Claude Code directory.
# We need to set up the expected path structure for detect_claude_code.
# Normalize the path first (cd && pwd) to match what memory-sync.sh does.
normalized="$(cd "$target" && pwd)"
encoded="$(echo "$normalized" | sed 's/\//-/g')"
claude_dir="$TMP_ROOT/.claude/projects/${encoded}/memory"
mkdir -p "$claude_dir"
cp "$fake_claude"/*.md "$claude_dir/"

# Override HOME so the script finds our fake .claude dir.
HOME="$TMP_ROOT" "$MEMORY_SYNC" --target "$target" --provider claude-code 2>&1 || fail 'memory-sync claude-code import failed'

# Check that shared memory was imported.
[ -f "$target/docs/.memory/shared/arch-module.md" ] \
  || fail 'shared memory arch-module.md was not imported'

# Check that local memory was imported.
[ -f "$target/docs/.memory/local/local-go-path.md" ] \
  || fail 'local memory local-go-path.md was not imported'

# Check that ambiguous memory defaulted to shared.
[ -f "$target/docs/.memory/shared/something.md" ] \
  || fail 'ambiguous memory something.md was not placed in shared/'

# Check that imported files have Compass frontmatter.
grep -qF 'scope: shared' "$target/docs/.memory/shared/arch-module.md" \
  || fail 'imported shared memory lacks scope frontmatter'
grep -qF 'scope: local' "$target/docs/.memory/local/local-go-path.md" \
  || fail 'imported local memory lacks scope frontmatter'
grep -qF 'source: claude-code' "$target/docs/.memory/shared/arch-module.md" \
  || fail 'imported memory lacks source frontmatter'

# Check that Claude Code YAML frontmatter was stripped.
if grep -qF 'node_type: memory' "$target/docs/.memory/shared/arch-module.md"; then
  fail 'imported memory still has Claude Code frontmatter'
fi

# --dry-run must not create files.
dry_target="$TMP_ROOT/dry-project"
mkdir -p "$dry_target/docs/.memory/shared" "$dry_target/docs/.memory/local"
# Set up Claude memories for the dry-run target path too.
dry_normalized="$(cd "$dry_target" && pwd)"
dry_encoded="$(echo "$dry_normalized" | sed 's/\//-/g')"
dry_claude_dir="$TMP_ROOT/.claude/projects/${dry_encoded}/memory"
mkdir -p "$dry_claude_dir"
cp "$fake_claude"/*.md "$dry_claude_dir/"
HOME="$TMP_ROOT" "$MEMORY_SYNC" --target "$dry_target" --provider claude-code --dry-run 2>&1 || fail 'memory-sync dry-run failed'
# Should have no imported files (only empty dirs).
shared_count=$(find "$dry_target/docs/.memory/shared" -type f | wc -l)
[ "$shared_count" -eq 0 ] || fail '--dry-run created files in shared/'

# Test validation: empty file should be skipped.
val_target="$TMP_ROOT/val-project"
mkdir -p "$val_target/docs/.memory/shared" "$val_target/docs/.memory/local"
val_normalized="$(cd "$val_target" && pwd)"
val_encoded="$(echo "$val_normalized" | sed 's/\//-/g')"
val_claude_dir="$TMP_ROOT/.claude/projects/${val_encoded}/memory"
mkdir -p "$val_claude_dir"
# Create an empty file.
: > "$val_claude_dir/empty.md"
# Create a file with only frontmatter.
cat > "$val_claude_dir/frontmatter-only.md" <<'EOF'
---
name: frontmatter-only
description: "Only frontmatter, no body"
---
EOF
# Create a valid file.
cat > "$val_claude_dir/valid.md" <<'EOF'
---
name: valid
description: "Valid memory"
---

This is valid content about architecture and modules.
EOF
val_output="$(HOME="$TMP_ROOT" "$MEMORY_SYNC" --target "$val_target" --provider claude-code 2>&1)"
echo "$val_output" | grep -qF 'SKIP (invalid): empty.md' || fail 'empty file not skipped'
echo "$val_output" | grep -qF 'SKIP (invalid): frontmatter-only.md' || fail 'frontmatter-only file not skipped'
echo "$val_output" | grep -qF 'SHARED: valid.md' || fail 'valid file not imported'
[ -f "$val_target/docs/.memory/shared/valid.md" ] || fail 'valid file not created'
[ ! -f "$val_target/docs/.memory/shared/empty.md" ] || fail 'empty file was created'
[ ! -f "$val_target/docs/.memory/shared/frontmatter-only.md" ] || fail 'frontmatter-only file was created'

# Test deduplication: running sync twice should not create duplicates.
dedup_target="$TMP_ROOT/dedup-project"
mkdir -p "$dedup_target/docs/.memory/shared" "$dedup_target/docs/.memory/local"
dedup_normalized="$(cd "$dedup_target" && pwd)"
dedup_encoded="$(echo "$dedup_normalized" | sed 's/\//-/g')"
dedup_claude_dir="$TMP_ROOT/.claude/projects/${dedup_encoded}/memory"
mkdir -p "$dedup_claude_dir"
cat > "$dedup_claude_dir/test-memory.md" <<'EOF'
---
name: test-memory
description: "Test memory for deduplication"
---

This is test content about architecture and modules for deduplication testing.
EOF
# First sync.
HOME="$TMP_ROOT" "$MEMORY_SYNC" --target "$dedup_target" --provider claude-code >/dev/null 2>&1 || fail 'first sync failed'
[ -f "$dedup_target/docs/.memory/shared/test-memory.md" ] || fail 'first sync did not create file'
# Second sync should detect duplicate.
dedup_output="$(HOME="$TMP_ROOT" "$MEMORY_SYNC" --target "$dedup_target" --provider claude-code 2>&1)"
echo "$dedup_output" | grep -qF 'duplicate: content matches' || fail 'duplicate not detected'
# File should still exist (not overwritten).
[ -f "$dedup_target/docs/.memory/shared/test-memory.md" ] || fail 'file missing after duplicate detection'

# ===== Memory Index Tests =====
MEMORY_INDEX="$ROOT_DIR/scripts/memory-index.sh"

# --help must work.
"$MEMORY_INDEX" --help | grep -qF 'memory-index' \
  || fail '--help missing usage info'

# Missing docs/.memory must fail.
mkdir -p "$TMP_ROOT/no-memory"
code=0
"$MEMORY_INDEX" --target "$TMP_ROOT/no-memory" >/dev/null 2>"$TMP_ROOT/err" || code=$?
[ "$code" -eq 1 ] || fail 'missing memory directory should exit 1'
grep -Fq 'memory directory not found' "$TMP_ROOT/err" || fail 'missing memory directory message'

# Create test memories for indexing.
idx_target="$TMP_ROOT/idx-project"
mkdir -p "$idx_target/docs/.memory/shared" "$idx_target/docs/.memory/local"

cat > "$idx_target/docs/.memory/shared/arch-decision.md" <<'EOF'
---
scope: shared
source: claude-code
imported: "2026-09-24T10:00:00Z"
summary: "Architecture decision about module boundaries"
---

The auth module owns all JWT logic.
EOF

cat > "$idx_target/docs/.memory/local/go-path.md" <<'EOF'
---
scope: local
source: claude-code
imported: "2026-09-24T10:00:00Z"
summary: "Go installation path"
---

Go is at /usr/local/go.
EOF

# Test full index (all scopes).
idx_output="$("$MEMORY_INDEX" --target "$idx_target")"
echo "$idx_output" | grep -qF 'path: "docs/.memory/shared/arch-decision.md"' || fail 'index missing shared memory'
echo "$idx_output" | grep -qF 'path: "docs/.memory/local/go-path.md"' || fail 'index missing local memory'
echo "$idx_output" | grep -qF 'scope: "shared"' || fail 'index missing shared scope'
echo "$idx_output" | grep -qF 'scope: "local"' || fail 'index missing local scope'
echo "$idx_output" | grep -qF 'source: "claude-code"' || fail 'index missing source'
echo "$idx_output" | grep -qF 'total: 2 (shared=1 local=1)' || fail 'index total count wrong'

# Test --scope shared filter.
shared_output="$("$MEMORY_INDEX" --target "$idx_target" --scope shared)"
echo "$shared_output" | grep -qF 'arch-decision.md' || fail 'shared filter missing shared memory'
echo "$shared_output" | grep -qF 'go-path.md' && fail 'shared filter should not include local memory' || true
echo "$shared_output" | grep -qF 'total: 1 (shared=1 local=0)' || fail 'shared filter count wrong'

# Test --scope local filter.
local_output="$("$MEMORY_INDEX" --target "$idx_target" --scope local)"
echo "$local_output" | grep -qF 'go-path.md' || fail 'local filter missing local memory'
echo "$local_output" | grep -qF 'arch-decision.md' && fail 'local filter should not include shared memory' || true
echo "$local_output" | grep -qF 'total: 1 (shared=0 local=1)' || fail 'local filter count wrong'

# Test memory without summary falls back to first body line.
cat > "$idx_target/docs/.memory/shared/no-summary.md" <<'EOF'
---
scope: shared
source: claude-code
imported: "2026-09-24T10:00:00Z"
---

First line of body content becomes the summary.
EOF
no_sum_output="$("$MEMORY_INDEX" --target "$idx_target")"
echo "$no_sum_output" | grep -qF 'First line of body content becomes the summary' || fail 'body fallback summary not extracted'

# ===== Lifecycle Tests =====

# Test --lifecycle mode exists and reports lifecycle field.
lifecycle_out="$("$MEMORY_INDEX" --target "$idx_target" --lifecycle)"
echo "$lifecycle_out" | grep -qF 'mode: lifecycle' || fail '--lifecycle missing mode field'
echo "$lifecycle_out" | grep -qF 'lifecycle:' || fail '--lifecycle missing lifecycle state'

# Test expired memory detection.
cat > "$idx_target/docs/.memory/shared/expired-test.md" <<'EOF'
---
scope: shared
source: claude-code
imported: "2026-01-01T10:00:00Z"
status: active
expires: "2026-06-01T00:00:00Z"
summary: "Expired memory test"
---
# Expired
Content.
EOF
lifecycle_out="$("$MEMORY_INDEX" --target "$idx_target" --lifecycle)"
echo "$lifecycle_out" | grep -qF 'lifecycle: "expired"' || fail 'expired memory not detected'

# Test archived memory detection.
cat > "$idx_target/docs/.memory/shared/archived-test.md" <<'EOF'
---
scope: shared
source: claude-code
imported: "2025-01-01T10:00:00Z"
status: archived
summary: "Archived memory test"
---
# Archived
Content.
EOF
lifecycle_out="$("$MEMORY_INDEX" --target "$idx_target" --lifecycle)"
echo "$lifecycle_out" | grep -qF 'lifecycle: "archived"' || fail 'archived memory not detected'

# Test active memory detection.
cat > "$idx_target/docs/.memory/shared/active-test.md" <<'EOF'
---
scope: shared
source: claude-code
imported: "2026-09-20T10:00:00Z"
status: active
summary: "Active memory test"
---
# Active
Content.
EOF
lifecycle_out="$("$MEMORY_INDEX" --target "$idx_target" --lifecycle)"
echo "$lifecycle_out" | grep -qF 'lifecycle: "active"' || fail 'active memory not detected'

# ===== Verbose / Audit Log Tests =====
MEMORY_SYNC="$ROOT_DIR/scripts/memory-sync.sh"

# --verbose must appear in --help.
"$MEMORY_SYNC" --help | grep -qF -- '--verbose' || fail '--help missing --verbose flag'

# Test --verbose creates sync-log.json when memories are imported.
verbose_target="$TMP_ROOT/verbose-project"
mkdir -p "$verbose_target"
verbose_normalized="$(cd "$verbose_target" && pwd)"
verbose_encoded="$(echo "$verbose_normalized" | sed 's/\//-/g')"
verbose_claude="$TMP_ROOT/.claude/projects/$verbose_encoded/memory"
mkdir -p "$verbose_claude"
cat > "$verbose_claude/verbose-test.md" <<'EOF'
---
description: "Verbose test memory"
---
# Verbose Test
This is about module architecture and layer boundaries.
EOF

verbose_out="$(HOME="$TMP_ROOT" "$MEMORY_SYNC" --target "$verbose_target" --verbose 2>&1)"
echo "$verbose_out" | grep -qF '[verbose]' || fail '--verbose should show [verbose] messages'

# Sync log should be created.
[ -f "$verbose_target/docs/.memory/sync-log.json" ] || fail '--verbose should create sync-log.json'

# Log should contain the import entry.
grep -qF '"outcome":"imported"' "$verbose_target/docs/.memory/sync-log.json" \
  || fail 'sync-log.json should contain imported entry'
grep -qF '"provider":"claude-code"' "$verbose_target/docs/.memory/sync-log.json" \
  || fail 'sync-log.json should contain provider'

printf 'Memory sync checks passed.\n'

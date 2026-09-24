#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
BOOTSTRAP="$SCRIPT_DIR/bootstrap-docs.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/compass-smoke.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    fail "expected failure: $*"
  fi
}

trap cleanup EXIT

cd "$ROOT_DIR"

presets="$($BOOTSTRAP --list-presets)"
for preset in clean-solid-tdd vertical-cupid-incremental ddd-solid-bdd existing-architecture-lock research-based infra-ops; do
  case "$presets" in
    *"$preset"*) ;;
    *) fail "preset list missing $preset" ;;
  esac
done

dry_run_target="$TMP_ROOT/dry-run-target"
"$BOOTSTRAP" --target "$dry_run_target" --preset clean-solid-tdd --dry-run >/dev/null

expect_failure "$BOOTSTRAP" --target "$TMP_ROOT/missing-preset"
expect_failure "$BOOTSTRAP" --target "$TMP_ROOT/unknown-preset" --preset does-not-exist

no_overwrite_target="$TMP_ROOT/no-overwrite-target"
"$BOOTSTRAP" --target "$no_overwrite_target" --preset existing-architecture-lock >/dev/null

sentinel='compass smoke sentinel: do not overwrite'
printf '%s\n' "$sentinel" > "$no_overwrite_target/docs/README.md"
"$BOOTSTRAP" --target "$no_overwrite_target" --preset existing-architecture-lock >/dev/null

content="$(<"$no_overwrite_target/docs/README.md")"
if [ "$content" != "$sentinel" ]; then
  fail 'bootstrap overwrote an existing docs/README.md without --force'
fi

# --skip-agents must not create AGENTS.md.
skip_agents_target="$TMP_ROOT/skip-agents"
"$BOOTSTRAP" --target "$skip_agents_target" --preset clean-solid-tdd --skip-agents >/dev/null
if [ -f "$skip_agents_target/AGENTS.md" ]; then
  fail '--skip-agents created AGENTS.md'
fi

# Bootstrap must append Compass block to an existing AGENTS.md without one.
append_target="$TMP_ROOT/append-agents"
mkdir -p "$append_target"
printf '%s\n' '# Existing agents' > "$append_target/AGENTS.md"
"$BOOTSTRAP" --target "$append_target" --preset clean-solid-tdd >/dev/null
if ! grep -qF '<!-- compass:start -->' "$append_target/AGENTS.md"; then
  fail 'bootstrap did not append Compass block to existing AGENTS.md'
fi
if ! grep -qF '# Existing agents' "$append_target/AGENTS.md"; then
  fail 'bootstrap overwrote existing AGENTS.md content instead of appending'
fi

# Bootstrap must replace an existing Compass block in AGENTS.md.
replace_target="$TMP_ROOT/replace-agents"
mkdir -p "$replace_target"
printf '%s\n' '<!-- compass:start -->' 'OLD BLOCK' '<!-- compass:end -->' '' '## Other' > "$replace_target/AGENTS.md"
"$BOOTSTRAP" --target "$replace_target" --preset clean-solid-tdd --force >/dev/null
if grep -qF 'OLD BLOCK' "$replace_target/AGENTS.md"; then
  fail 'bootstrap did not replace old Compass block in AGENTS.md'
fi
if ! grep -qF '## Other' "$replace_target/AGENTS.md"; then
  fail 'bootstrap removed non-Compass content from AGENTS.md'
fi

# When CLAUDE.md exists, bootstrap must write to it and not create AGENTS.md.
claude_target="$TMP_ROOT/claude-detect"
mkdir -p "$claude_target"
printf '%s\n' '# Claude project' > "$claude_target/CLAUDE.md"
"$BOOTSTRAP" --target "$claude_target" --preset clean-solid-tdd >/dev/null
if ! grep -qF '<!-- compass:start -->' "$claude_target/CLAUDE.md"; then
  fail 'bootstrap did not write Compass block to existing CLAUDE.md'
fi
if [ -f "$claude_target/AGENTS.md" ]; then
  fail 'bootstrap createded AGENTS.md when CLAUDE.md was the only gateway'
fi

# When multiple gateway files exist, bootstrap must write to all of them.
multi_target="$TMP_ROOT/multi-gateway"
mkdir -p "$multi_target"
printf '%s\n' '# Agents' > "$multi_target/AGENTS.md"
printf '%s\n' '# Claude' > "$multi_target/CLAUDE.md"
"$BOOTSTRAP" --target "$multi_target" --preset clean-solid-tdd >/dev/null
if ! grep -qF '<!-- compass:start -->' "$multi_target/AGENTS.md"; then
  fail 'bootstrap did not write to AGENTS.md in multi-gateway scenario'
fi
if ! grep -qF '<!-- compass:start -->' "$multi_target/CLAUDE.md"; then
  fail 'bootstrap did not write to CLAUDE.md in multi-gateway scenario'
fi

# When .claude/rules/ exists, bootstrap must create compass.md there.
rules_target="$TMP_ROOT/claude-rules"
mkdir -p "$rules_target/.claude/rules"
"$BOOTSTRAP" --target "$rules_target" --preset clean-solid-tdd >/dev/null
if ! grep -qF '<!-- compass:start -->' "$rules_target/.claude/rules/compass.md"; then
  fail 'bootstrap did not create compass.md in .claude/rules/'
fi

# --agents-file must override auto-detection.
override_target="$TMP_ROOT/agents-override"
mkdir -p "$override_target"
printf '%s\n' '# Claude' > "$override_target/CLAUDE.md"
"$BOOTSTRAP" --target "$override_target" --preset clean-solid-tdd --agents-file CUSTOM.md >/dev/null
if ! grep -qF '<!-- compass:start -->' "$override_target/CUSTOM.md"; then
  fail '--agents-file did not create the specified file'
fi
if grep -qF '<!-- compass:start -->' "$override_target/CLAUDE.md"; then
  fail '--agents-file wrote to CLAUDE.md instead of only the specified file'
fi

# Gateway block must be router-first: directive to invoke Compass before any
# file edit, and must NOT list doc file paths that invite manual reading.
gw_target="$TMP_ROOT/gw-content"
mkdir -p "$gw_target"
"$BOOTSTRAP" --target "$gw_target" --preset clean-solid-tdd >/dev/null
gw_content="$(<"$gw_target/AGENTS.md")"
case "$gw_content" in
  *"invoke the"*Compass*"first"*|*"Invoke Compass skill"*) ;;
  *) fail 'gateway block missing router-first directive to invoke Compass' ;;
esac
if grep -qF '| Doc | Purpose |' "$gw_target/AGENTS.md"; then
  fail 'gateway block still contains Key Docs table — invites manual doc reading'
fi
if grep -qF 'docs/decisions/0001-orientation-lock.md' "$gw_target/AGENTS.md"; then
  fail 'gateway block still lists doc file paths'
fi
# Block must be compact: count lines between compass markers.
block_lines=$(awk '/<!-- compass:start -->/{p=1} p{c++} /<!-- compass:end -->/{print c; exit}' "$gw_target/AGENTS.md")
if [ "${block_lines:-0}" -gt 25 ]; then
  fail "gateway block too long ($block_lines lines); should be compact router, not doc reference"
fi

printf 'Smoke tests passed.\n'

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
RESOLVE="$ROOT_DIR/scripts/resolve-workflows.sh"
BOOTSTRAP="$ROOT_DIR/scripts/bootstrap-docs.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/compass-resolve-wf.XXXXXX")"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

# ===== --help must work =====
"$RESOLVE" --help | grep -qF 'resolve-workflows' \
  || fail '--help missing usage info'

# ===== Validate on project without custom-workflows.xml =====
no_custom="$TMP_ROOT/no-custom"
"$BOOTSTRAP" --target "$no_custom" --preset clean-solid-tdd > /dev/null 2>&1
rm -f "$no_custom/docs/process/custom-workflows.xml"
output=$("$RESOLVE" --target "$no_custom" --validate 2>&1)
echo "$output" | grep -qF 'No custom-workflows.xml found' \
  || fail 'should report missing custom-workflows.xml as optional'

# ===== Validate with valid custom workflow =====
valid="$TMP_ROOT/valid"
"$BOOTSTRAP" --target "$valid" --preset clean-solid-tdd > /dev/null 2>&1
cat > "$valid/docs/process/custom-workflows.xml" <<'XMLEOF'
<?xml version="1.0" encoding="UTF-8" ?>
<custom-workflows>
  <purpose>Project-specific workflows.</purpose>
  <workflow type="data_pipeline">
    <description>Add or modify a data pipeline stage.</description>
    <steps>
      <step order="1">Identify data sources.</step>
      <step order="2">Add schema validation.</step>
    </steps>
    <evidence>Schema validation and tests.</evidence>
  </workflow>
</custom-workflows>
XMLEOF

output=$("$RESOLVE" --target "$valid" --validate 2>&1)
echo "$output" | grep -qF 'data_pipeline' \
  || fail 'should detect data_pipeline workflow'
echo "$output" | grep -qF 'Validation PASSED' \
  || fail 'valid custom workflow should pass validation'

# ===== Validate detects conflict with preset type =====
conflict="$TMP_ROOT/conflict"
"$BOOTSTRAP" --target "$conflict" --preset clean-solid-tdd > /dev/null 2>&1
cat > "$conflict/docs/process/custom-workflows.xml" <<'XMLEOF'
<?xml version="1.0" encoding="UTF-8" ?>
<custom-workflows>
  <purpose>Conflicting workflows.</purpose>
  <workflow type="bug_fix">
    <description>This conflicts with preset.</description>
    <steps>
      <step order="1">Custom fix.</step>
    </steps>
    <evidence>Custom evidence.</evidence>
  </workflow>
</custom-workflows>
XMLEOF

code=0
"$RESOLVE" --target "$conflict" --validate > /dev/null 2>&1 || code=$?
[ "$code" -eq 1 ] || fail 'conflicting workflow type should exit 1'
output=$("$RESOLVE" --target "$conflict" --validate 2>&1 || true)
echo "$output" | grep -qF 'CONFLICT' \
  || fail 'should report CONFLICT for preset type collision'

# ===== Validate detects missing steps/phases =====
no_steps="$TMP_ROOT/no-steps"
"$BOOTSTRAP" --target "$no_steps" --preset clean-solid-tdd > /dev/null 2>&1
cat > "$no_steps/docs/process/custom-workflows.xml" <<'XMLEOF'
<?xml version="1.0" encoding="UTF-8" ?>
<custom-workflows>
  <purpose>Invalid workflow.</purpose>
  <workflow type="my_workflow">
    <description>Has no steps or phases.</description>
    <evidence>No evidence.</evidence>
  </workflow>
</custom-workflows>
XMLEOF

code=0
"$RESOLVE" --target "$no_steps" --validate > /dev/null 2>&1 || code=$?
[ "$code" -eq 1 ] || fail 'workflow without steps/phases should exit 1'

# ===== Merge produces combined file =====
merge_target="$TMP_ROOT/merge"
"$BOOTSTRAP" --target "$merge_target" --preset clean-solid-tdd > /dev/null 2>&1
cat > "$merge_target/docs/process/custom-workflows.xml" <<'XMLEOF'
<?xml version="1.0" encoding="UTF-8" ?>
<custom-workflows>
  <purpose>Project-specific workflows.</purpose>
  <workflow type="data_pipeline">
    <description>Pipeline workflow.</description>
    <steps>
      <step order="1">Step one.</step>
    </steps>
    <evidence>Pipeline evidence.</evidence>
  </workflow>
</custom-workflows>
XMLEOF

resolved="$merge_target/docs/process/resolved-workflows.xml"
"$RESOLVE" --target "$merge_target" --output "$resolved"
[ -f "$resolved" ] || fail 'resolved file not created'

# Must contain preset workflows
grep -qF 'type="new_feature"' "$resolved" \
  || fail 'resolved file missing preset new_feature workflow'
grep -qF 'type="bug_fix"' "$resolved" \
  || fail 'resolved file missing preset bug_fix workflow'

# Must contain custom workflow
grep -qF 'type="data_pipeline"' "$resolved" \
  || fail 'resolved file missing custom data_pipeline workflow'

# ===== Dry-run merge should not write =====
dry="$TMP_ROOT/dry-merge"
"$BOOTSTRAP" --target "$dry" --preset clean-solid-tdd > /dev/null 2>&1
cat > "$dry/docs/process/custom-workflows.xml" <<'XMLEOF'
<?xml version="1.0" encoding="UTF-8" ?>
<custom-workflows>
  <purpose>Test.</purpose>
  <workflow type="test_wf">
    <description>Test.</description>
    <steps><step order="1">Test.</step></steps>
    <evidence>Test.</evidence>
  </workflow>
</custom-workflows>
XMLEOF

dry_out="$dry/docs/process/resolved.xml"
"$RESOLVE" --target "$dry" --output "$dry_out" --dry-run > /dev/null 2>&1
[ ! -f "$dry_out" ] || fail '--dry-run merge should not create output file'

# ===== Commented-out workflows should be ignored =====
commented="$TMP_ROOT/commented"
"$BOOTSTRAP" --target "$commented" --preset clean-solid-tdd > /dev/null 2>&1
# The default template has all workflows commented out
output=$("$RESOLVE" --target "$commented" --validate 2>&1)
echo "$output" | grep -qF 'No custom workflow types defined' \
  || fail 'commented-out workflows should be reported as none defined'

printf 'Resolve-workflows checks passed.\n'

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
CHECK="$ROOT_DIR/scripts/skills-check.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/compass-skills-check.XXXXXX")"

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

# Prints the YAML block of one skill entry.
skill_block() {
  printf '%s\n' "$1" | awk -v name="$2" '/^[^ ]/{p=0} /^  - name: /{p=($0=="  - name: \"" name "\"")} p'
}

add_skill() {
  mkdir -p "$1/$2"
  printf -- '---\nname: %s\n---\n' "$2" > "$1/$2/SKILL.md"
}

trap cleanup EXIT

[ -x "$CHECK" ] || fail 'missing executable script: scripts/skills-check.sh'

manifest="$TMP_ROOT/recommended-skills.xml"
cat > "$manifest" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<recommended-skills>
  <purpose>Fixture manifest.</purpose>
  <skill name="alpha" source="owner/alpha-repo" phase="design">Alpha purpose.</skill>
  <skill name="beta" source="owner/beta-repo" phase="implementation">Beta purpose.</skill>
  <skill name="gamma" source="owner/gamma-repo" phase="debugging">Gamma purpose.</skill>
  <skill name="delta" source="owner/delta-repo" phase="review">Delta purpose.</skill>
  <skill name="broken" phase="review">Missing source.</skill>
</recommended-skills>
EOF

canonical="$TMP_ROOT/agents-skills"
agent="$TMP_ROOT/agent-skills"
add_skill "$canonical" alpha
add_skill "$canonical" gamma
add_skill "$agent" delta

lock="$TMP_ROOT/skill-lock.json"
cat > "$lock" <<'EOF'
{
  "version": 3,
  "skills": {
    "alpha": {
      "source": "owner/alpha-repo",
      "skillPath": "skills/alpha/SKILL.md"
    }
  },
  "dismissed": {}
}
EOF

project="$TMP_ROOT/project"
mkdir -p "$project/docs/process"
cat > "$project/docs/process/recommended-skills.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<recommended-skills>
  <skill name="epsilon" source="owner/epsilon-repo" phase="analysis">Project extra.</skill>
  <skill name="alpha" source="other/alpha-fork" phase="design">Duplicate of a core skill.</skill>
</recommended-skills>
EOF

output="$("$CHECK" --manifest "$manifest" --lock "$lock" --skills-dir "$canonical" --skills-dir "$agent" --target "$project")"

[ "$(skill_block "$output" alpha)" = '  - name: "alpha"
    source: "owner/alpha-repo"
    phase: "design"
    status: "installed"
    managed: true' ] || fail "installed and managed skill block, got: $(skill_block "$output" alpha)"

[ "$(skill_block "$output" beta)" = '  - name: "beta"
    source: "owner/beta-repo"
    phase: "implementation"
    status: "missing"
    managed: false' ] || fail "missing skill block, got: $(skill_block "$output" beta)"

require_line "$(skill_block "$output" gamma)" '    status: "installed"' 'hand-installed skill is installed'
require_line "$(skill_block "$output" gamma)" '    managed: false' 'hand-installed skill is not managed'
require_line "$(skill_block "$output" delta)" '    status: "installed"' 'skill found in an agent folder'
require_line "$(skill_block "$output" epsilon)" '    source: "owner/epsilon-repo"' 'project extra skill'
require_line "$output" 'missing: 2' 'missing count'
require_line "$output" '  - "npx skills add owner/beta-repo --skill beta -g"' 'install command for a missing core skill'
require_line "$output" '  - "npx skills add owner/epsilon-repo --skill epsilon -g"' 'install command for a missing project skill'
require_line "$output" '  - "invalid skill entry in recommended-skills.xml: broken has no source"' 'invalid manifest entry'
reject_text "$output" 'other/alpha-fork' 'duplicate names keep the first entry'
reject_text "$output" 'npx skills add owner/alpha-repo' 'installed skills need no install command'
[ "$(printf '%s\n' "$output" | grep -c '^  - name: "alpha"$')" -eq 1 ] || fail 'duplicate skill listed twice'

no_lock="$("$CHECK" --manifest "$manifest" --lock "$TMP_ROOT/missing-lock.json" --skills-dir "$canonical")"
require_line "$(skill_block "$no_lock" alpha)" '    managed: false' 'missing lock file means unmanaged'

default_output="$("$CHECK" --lock "$TMP_ROOT/missing-lock.json" --skills-dir "$TMP_ROOT/empty-skills")"
require_line "$default_output" 'missing: 6' 'Compass core manifest lists six skills'
require_line "$default_output" '  - "npx skills add obra/superpowers --skill brainstorming -g"' 'core install command'
reject_text "$default_output" 'invalid skill entry' 'Compass core manifest entries are complete'

code=0
"$CHECK" --skills-dir >/dev/null 2>&1 || code=$?
[ "$code" -eq 2 ] || fail "--skills-dir without value should exit 2, got $code"

printf 'Skills check passed.\n'

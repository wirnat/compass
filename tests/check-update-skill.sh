#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
UPDATE_SCRIPT="$ROOT_DIR/scripts/update-skill.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/compass-update-skill.XXXXXX")"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  rm -rf "$TMP_ROOT"
}

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    fail "expected failure: $*"
  fi
}

write_source_file() {
  local path="$1"
  local content="$2"

  mkdir -p "$(dirname -- "$path")"
  printf '%s\n' "$content" > "$path"
}

create_source_repo() {
  local repo="$1"

  mkdir -p "$repo"
  git -C "$repo" init --quiet --initial-branch=main

  write_source_file "$repo/SKILL.md" 'source skill v1'
  write_source_file "$repo/README.md" 'source readme v1'
  write_source_file "$repo/agents/openai.yaml" 'name: compass'
  write_source_file "$repo/assets/docs-seed/README.md" 'source docs seed'
  write_source_file "$repo/docs/README.md" 'source docs'
  write_source_file "$repo/references/task-types.xml" '<task-types-reference />'
  write_source_file "$repo/scripts/bootstrap-docs.sh" '#!/usr/bin/env bash'

  git -C "$repo" add .
  git -C "$repo" -c user.name='Compass Test' -c user.email='compass@example.invalid' commit --quiet -m 'seed source repo'
}

trap cleanup EXIT

source_repo="$TMP_ROOT/source-repo"
create_source_repo "$source_repo"
source_url="file://$source_repo"
remote_rev="$(git -C "$source_repo" rev-parse HEAD)"

up_to_date_skill="$TMP_ROOT/up-to-date-skill"
mkdir -p "$up_to_date_skill"
printf 'installed skill\n' > "$up_to_date_skill/SKILL.md"
cat > "$up_to_date_skill/.compass-source-revision" <<META
revision=$remote_rev
repo_url=$source_repo
branch=main
updated_at=2026-06-08T00:00:00Z
META

check_output="$($UPDATE_SCRIPT --skill-dir "$up_to_date_skill" --repo-url "$source_url" --branch main --check)"
case "$check_output" in
  *"Compass skill up to date: $remote_rev"*) ;;
  *) fail "--check did not report up-to-date local metadata" ;;
esac

stale_skill="$TMP_ROOT/stale-skill"
mkdir -p "$stale_skill"
printf 'old skill\n' > "$stale_skill/SKILL.md"

update_output="$($UPDATE_SCRIPT --skill-dir "$stale_skill" --repo-url "$source_url" --branch main)"
case "$update_output" in
  *"Compass skill updated:"*) ;;
  *) fail 'non-git skill update did not report success' ;;
esac

if [ "$(<"$stale_skill/SKILL.md")" != 'source skill v1' ]; then
  fail 'non-git skill update did not copy SKILL.md from source repo'
fi

if ! grep -Fq "revision=$remote_rev" "$stale_skill/.compass-source-revision"; then
  fail 'non-git skill update did not write remote revision metadata'
fi

expect_failure "$UPDATE_SCRIPT" --skill-dir "$TMP_ROOT/not-a-skill" --repo-url "$source_url" --branch main --check
expect_failure "$UPDATE_SCRIPT" --skill-dir "$up_to_date_skill" --repo-url "$source_url" --branch does-not-exist --check

printf 'Update-skill checks passed.\n'

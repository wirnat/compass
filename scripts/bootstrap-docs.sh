#!/usr/bin/env bash
set -euo pipefail

target_dir="$(pwd)"
force=0
dry_run=0
skip_agents=0
agents_files_override=""
preset=""
validate=0
update=0

usage() {
  cat <<'USAGE'
Usage: bootstrap-docs.sh [--target DIR] --preset NAME [--force] [--dry-run]
       bootstrap-docs.sh --list-presets
       bootstrap-docs.sh --target DIR --validate
       bootstrap-docs.sh [--target DIR] --preset NAME --update

Copy Compass seed documentation, orientation lock, and preset process docs into DIR.

Options:
  --target DIR    Project directory to seed. Defaults to current directory.
  --preset NAME   Orientation preset to apply. Required unless --list-presets or --validate.
  --force         Overwrite existing files.
  --dry-run       Print planned actions without writing files.
  --skip-agents   Do not create or update agent gateway files.
  --agents-file F Write Compass block to F instead of auto-detecting (repeatable).
  --list-presets  Print available orientation presets with short descriptions.
  --validate      Validate existing Compass docs without writing. Checks required files,
                  workflow XML, orientation lock, and gateway markers.
  --update        Incremental update: only overwrite files whose seed source changed.
                  Preserves user-edited files. Reports conflicts when both sides changed.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
seed_dir="$(cd "$script_dir/../assets/docs-seed" && pwd)"
preset_root="$(cd "$script_dir/../assets/orientation-presets" && pwd)"

list_presets() {
  cat <<'PRESETS'
clean-solid-tdd
  Short: Enterprise-grade Clean Architecture layering, explicit folder/file structure, SOLID, and TDD.
  Best fit: frontend, backend, full-stack, API, and business systems that need protected dependency direction, clear boundaries, and test-first discipline.

vertical-cupid-incremental
  Short: Vertical Slice Architecture, explicit feature-slice structure, CUPID/YAGNI/KISS, and incremental tests.
  Best fit: small to medium products that benefit from feature-local change, low ceremony, and avoiding over-layering.

ddd-solid-bdd
  Short: Domain-Driven Design, explicit bounded-context structure, domain modeling, SOLID, and BDD plus TDD.
  Best fit: complex business domains that need ubiquitous language, bounded contexts, aggregates, and executable behavior examples.

existing-architecture-lock
  Short: Preserve and document the architecture, principles, and workflow already present in the project.
  Best fit: mature projects with a coherent existing structure that should be extended instead of replaced.

research-based
  Short: Research current sources, compare options, cite evidence, then lock the selected architecture, principles, and workflow.
  Best fit: unknown domains, unfamiliar teams, or cases where the user explicitly asks Compass to research alternatives.

infra-ops
  Short: Declared-state infrastructure operations with risk-tiered live-change gates, plan or dry-run before apply, and live verification.
  Best fit: infrastructure, platform, and operations repositories: IaC, configuration management, cluster manifests, and server fleets.
PRESETS
}

# Validate existing Compass docs without writing.
validate_docs() {
  local target="$1"
  local errors=0
  local warnings=0

  echo "=== Compass Docs Validation ==="
  echo ""
  echo "Target: $target"
  echo ""

  # Check required files exist and are non-empty
  local required_files=(
    "docs/README.md"
    "docs/decisions/0001-orientation-lock.md"
    "docs/foundation/engineering-philosophy.md"
    "docs/foundation/architecture-principles.md"
    "docs/foundation/testing-principles.md"
    "docs/process/workflows.xml"
    "docs/architecture/README.md"
    "docs/modules/README.md"
    "docs/reference/note-schema.md"
  )

  echo "Checking required files..."
  for file in "${required_files[@]}"; do
    if [[ ! -f "$target/$file" ]]; then
      echo "  ✗ MISSING: $file"
      errors=$((errors + 1))
    elif [[ ! -s "$target/$file" ]]; then
      echo "  ✗ EMPTY: $file"
      errors=$((errors + 1))
    else
      echo "  ✓ $file"
    fi
  done
  echo ""

  # Check workflows.xml is valid XML (basic check)
  echo "Checking workflows.xml..."
  if [[ -f "$target/docs/process/workflows.xml" ]]; then
    if grep -q '<?xml' "$target/docs/process/workflows.xml" && grep -q '</workflows' "$target/docs/process/workflows.xml"; then
      echo "  ✓ workflows.xml appears valid"
    else
      echo "  ✗ workflows.xml may be malformed"
      errors=$((errors + 1))
    fi
  fi
  echo ""

  # Check orientation lock references a valid preset
  echo "Checking orientation lock..."
  if [[ -f "$target/docs/decisions/0001-orientation-lock.md" ]]; then
    local found_preset=0
    for preset_dir in "$preset_root"/*/; do
      local preset_name
      preset_name="$(basename "$preset_dir")"
      if grep -q "$preset_name" "$target/docs/decisions/0001-orientation-lock.md"; then
        echo "  ✓ References preset: $preset_name"
        found_preset=1
        break
      fi
    done
    if [[ "$found_preset" -eq 0 ]]; then
      echo "  ⚠ No recognized preset found in orientation lock"
      warnings=$((warnings + 1))
    fi
  fi
  echo ""

  # Check gateway files have Compass markers
  echo "Checking gateway files..."
  local gateway_found=0
  local gateway_names=(AGENTS.md CLAUDE.md GEMINI.md COPILOT.md)
  for name in "${gateway_names[@]}"; do
    if [[ -f "$target/$name" ]]; then
      if grep -q '<!-- compass:start -->' "$target/$name"; then
        echo "  ✓ $name has Compass block"
        gateway_found=1
      else
        echo "  ⚠ $name exists but missing Compass block"
        warnings=$((warnings + 1))
      fi
    fi
  done
  # Check .claude/rules/ and .cursor/rules/
  if [[ -f "$target/.claude/rules/compass.md" ]]; then
    if grep -q '<!-- compass:start -->' "$target/.claude/rules/compass.md"; then
      echo "  ✓ .claude/rules/compass.md has Compass block"
      gateway_found=1
    fi
  fi
  if [[ -f "$target/.cursor/rules/compass.mdc" ]]; then
    if grep -q '<!-- compass:start -->' "$target/.cursor/rules/compass.mdc"; then
      echo "  ✓ .cursor/rules/compass.mdc has Compass block"
      gateway_found=1
    fi
  fi
  if [[ "$gateway_found" -eq 0 ]]; then
    echo "  ⚠ No gateway files with Compass block found"
    warnings=$((warnings + 1))
  fi
  echo ""

  # Check memory structure
  echo "Checking memory structure..."
  if [[ -d "$target/docs/.memory/shared" && -d "$target/docs/.memory/local" ]]; then
    echo "  ✓ Memory structure exists"
    local shared_count local_count
    shared_count=$(find "$target/docs/.memory/shared" -type f -name '*.md' | wc -l | tr -d ' ')
    local_count=$(find "$target/docs/.memory/local" -type f -name '*.md' | wc -l | tr -d ' ')
    echo "    Shared memories: $shared_count"
    echo "    Local memories: $local_count"
  else
    echo "  ⚠ Memory structure not initialized"
    warnings=$((warnings + 1))
  fi
  echo ""

  # Summary
  echo "=== Validation Summary ==="
  echo "Errors: $errors"
  echo "Warnings: $warnings"
  echo ""

  if [[ "$errors" -gt 0 ]]; then
    echo "❌ Validation FAILED with $errors error(s)"
    return 1
  elif [[ "$warnings" -gt 0 ]]; then
    echo "⚠️  Validation PASSED with $warnings warning(s)"
    return 0
  else
    echo "✅ Validation PASSED"
    return 0
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --target" >&2
        exit 2
      fi
      target_dir="$2"
      shift 2
      ;;
    --preset)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --preset" >&2
        exit 2
      fi
      preset="$2"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --skip-agents)
      skip_agents=1
      shift
      ;;
    --agents-file)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --agents-file" >&2
        exit 2
      fi
      agents_files_override="${agents_files_override:+${agents_files_override},}$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --list-presets)
      list_presets
      exit 0
      ;;
    --validate)
      validate=1
      shift
      ;;
    --update)
      update=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# Handle --validate mode (doesn't require --preset)
if [[ "$validate" -eq 1 ]]; then
  if [[ ! -d "$target_dir" ]]; then
    echo "target directory not found: $target_dir" >&2
    exit 1
  fi
  target_dir="$(cd "$target_dir" && pwd)"
  validate_docs "$target_dir"
  exit $?
fi

if [[ -z "$preset" ]]; then
  echo "missing required --preset" >&2
  echo "choose one preset before bootstrapping:" >&2
  list_presets >&2
  exit 2
fi

if [[ ! -d "$preset_root/$preset/docs" ]]; then
  echo "unknown preset: $preset" >&2
  echo "available presets:" >&2
  list_presets >&2
  exit 2
fi

if [[ ! -d "$target_dir" ]]; then
  if [[ "$dry_run" -eq 1 ]]; then
    echo "mkdir $target_dir"
    target_parent="$(cd "$(dirname "$target_dir")" && pwd)"
    target_dir="$target_parent/$(basename "$target_dir")"
  else
    mkdir -p "$target_dir"
    target_dir="$(cd "$target_dir" && pwd)"
  fi
else
  target_dir="$(cd "$target_dir" && pwd)"
fi

created=0
skipped=0
overwritten=0

compass_agents_block() {
  cat <<'AGENTS'
<!-- compass:start -->
# Compass — Engineering Workflow

This project uses [Compass](https://github.com/wirnat/compass) for engineering
workflow enforcement. Architecture, process, and module documentation live
under `docs/`. The authoritative workflow reference is
`docs/process/workflows.xml`.

## Always Do

- **MUST load the Compass skill and run its Session Update Gate** before any
  implementation, docs, or planning work.
- **MUST classify the task type** from `docs/process/workflows.xml` before the
  first file edit: `new_feature`, `feature_update`, `bug_fix`, `refactor`,
  `architecture_change`, `docs_only`, etc.
- **MUST run `scripts/docs-index.sh`** after creating or modifying any note
  under `docs/`.
- **MUST report gate outcomes** before implementation: Session Update
  (pass/skip), task memory (created/resumed/not-required).

## Never Do

- NEVER start implementation without stating the workflow type and gate
  outcomes.
- NEVER edit locked architecture without a decision record under
  `docs/decisions/`.
- NEVER skip the Task Memory Gate for long or risky multi-slice work.

## Key Docs

| Doc | Purpose |
|---|---|
| `docs/decisions/0001-orientation-lock.md` | Architecture preset and locked orientation |
| `docs/process/workflows.xml` | Active workflow types, risk tiers, gates |
| `docs/foundation/engineering-philosophy.md` | Engineering philosophy |
| `docs/foundation/architecture-principles.md` | Architecture principles |
| `docs/foundation/testing-principles.md` | Testing principles |
<!-- compass:end -->
AGENTS
}

# Writes or replaces the compass block inside a Markdown gateway file.
# Returns: created | appended | updated
update_gateway_file() {
  local gateway_file="$1"
  local dry="$2"
  local block
  block="$(compass_agents_block)"

  if [[ "$dry" -eq 1 ]]; then
    if [[ ! -f "$gateway_file" ]]; then
      echo "create $gateway_file with Compass block"
      echo "created"
    elif grep -qF '<!-- compass:start -->' "$gateway_file"; then
      echo "update Compass block in $gateway_file"
      echo "updated"
    else
      echo "append Compass block to $gateway_file"
      echo "appended"
    fi
    return
  fi

  # Ensure parent directory exists (e.g. .claude/rules/).
  mkdir -p "$(dirname "$gateway_file")"

  # File does not exist — create with only the Compass block.
  if [[ ! -f "$gateway_file" ]]; then
    printf '%s\n' "$block" > "$gateway_file"
    echo "created"
    return
  fi

  # File exists and already has a Compass block — replace it in place.
  if grep -qF '<!-- compass:start -->' "$gateway_file"; then
    local tmp="${gateway_file}.tmp"
    awk '
      /<!-- compass:start -->/ { skip=1; next }
      /<!-- compass:end -->/   { skip=0; next }
      !skip { print }
    ' "$gateway_file" > "$tmp"
    awk 'NR==1 && /^[[:space:]]*$/ { next } { print }' "$tmp" > "${tmp}.2"
    mv "${tmp}.2" "$tmp"
    {
      printf '%s\n' "$block"
      if [[ -s "$tmp" ]]; then
        first_char="$(head -c 1 "$tmp")"
        if [[ "$first_char" != $'\n' ]]; then
          printf '\n'
        fi
        cat "$tmp"
      fi
    } > "$gateway_file"
    rm -f "$tmp"
    echo "updated"
    return
  fi

  # File exists but has no Compass block — append.
  {
    if [[ -s "$gateway_file" ]]; then
      last_char="$(tail -c 1 "$gateway_file")"
      if [[ "$last_char" != $'\n' ]]; then
        printf '\n'
      fi
      printf '\n'
    fi
    printf '%s\n' "$block"
  } >> "$gateway_file"
  echo "appended"
}

# Detects which agent gateway files exist in the project and writes the
# Compass block to each one. Falls back to AGENTS.md when none are found.
detect_and_write_gateways() {
  local target="$1"
  local dry="$2"
  local override="$3"
  local results=()

  # Explicit override: write only to the specified file(s).
  if [[ -n "$override" ]]; then
    IFS=',' read -ra files <<< "$override"
    for f in "${files[@]}"; do
      local abs="$f"
      [[ "$f" = /* ]] || abs="$target/$f"
      local status
      status="$(update_gateway_file "$abs" "$dry")"
      results+=("$(basename "$abs"):$status")
    done
    local IFS=,
    echo "${results[*]}"
    return
  fi

  local found=0
  local gateway_names=(AGENTS.md CLAUDE.md GEMINI.md COPILOT.md)

  for name in "${gateway_names[@]}"; do
    if [[ -f "$target/$name" ]]; then
      local status
      status="$(update_gateway_file "$target/$name" "$dry")"
      results+=("$name:$status")
      found=1
    fi
  done

  # Check .claude/rules/ directory.
  if [[ -d "$target/.claude/rules" ]]; then
    local status
    status="$(update_gateway_file "$target/.claude/rules/compass.md" "$dry")"
    results+=(".claude/rules/compass.md:$status")
    found=1
  fi

  # Check .cursor/rules/ directory.
  if [[ -d "$target/.cursor/rules" ]]; then
    local status
    status="$(update_gateway_file "$target/.cursor/rules/compass.mdc" "$dry")"
    results+=(".cursor/rules/compass.mdc:$status")
    found=1
  fi

  # Fallback: no existing gateway files — create AGENTS.md.
  if [[ "$found" -eq 0 ]]; then
    local status
    status="$(update_gateway_file "$target/AGENTS.md" "$dry")"
    results+=("AGENTS.md:$status")
  fi

  local IFS=,
  echo "${results[*]}"
}

copy_tree() {
  local source_dir="$1"
  local dest_root="$2"

  while IFS= read -r dir; do
    rel="${dir#"$source_dir"}"
    [[ -z "$rel" ]] && continue
    if [[ "$dry_run" -eq 1 ]]; then
      if [[ ! -d "$dest_root$rel" ]]; then
        echo "mkdir $dest_root$rel"
      fi
    else
      mkdir -p "$dest_root$rel"
    fi
  done < <(find "$source_dir" -type d | sort)

  while IFS= read -r src; do
    rel="${src#"$source_dir"/}"
    dest="$dest_root/$rel"

    if [[ -e "$dest" && "$force" -ne 1 ]]; then
      echo "skip $dest"
      skipped=$((skipped + 1))
      continue
    fi

    if [[ "$dry_run" -eq 1 ]]; then
      if [[ -e "$dest" ]]; then
        echo "overwrite $dest"
        overwritten=$((overwritten + 1))
      else
        echo "create $dest"
        created=$((created + 1))
      fi
      continue
    fi

    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" ]]; then
      overwritten=$((overwritten + 1))
    else
      created=$((created + 1))
    fi
    cp "$src" "$dest"
  done < <(find "$source_dir" -type f | sort)
}

# Generate a manifest of seed file checksums for incremental updates.
# Format: <sha256>  <relative-path>
# Stored at docs/.compass-manifest (committed to git).
generate_manifest() {
  local target="$1"
  local manifest="$target/docs/.compass-manifest"

  if [[ "$dry_run" -eq 1 ]]; then
    echo "generate $manifest (dry-run)"
    return
  fi

  {
    # Seed files
    while IFS= read -r src; do
      local rel="${src#"$seed_dir"/}"
      local hash
      hash="$(shasum -a 256 "$src" | cut -d' ' -f1)"
      echo "$hash  $rel"
    done < <(find "$seed_dir" -type f | sort)

    # Preset files
    while IFS= read -r src; do
      local rel="${src#"$preset_root/$preset/docs"/}"
      local hash
      hash="$(shasum -a 256 "$src" | cut -d' ' -f1)"
      echo "$hash  $rel"
    done < <(find "$preset_root/$preset/docs" -type f | sort)
  } | sort -u > "$manifest"
}

# Incremental update: compare seed files against manifest and current state.
# Three-way logic:
#   - seed unchanged, current unchanged → skip (no action)
#   - seed changed, current unchanged → update (seed wins)
#   - seed unchanged, current changed → skip (user customization preserved)
#   - seed changed, current changed → conflict (report, skip unless --force)
#   - new seed file, not in manifest → add
update_docs() {
  local target="$1"
  local manifest="$target/docs/.compass-manifest"
  local updated=0 added=0 conflicts=0 preserved=0 unchanged=0

  echo "=== Compass Incremental Update ==="
  echo ""
  echo "Target: $target"
  echo "Preset: $preset"
  echo ""

  if [[ ! -f "$manifest" ]]; then
    echo "No manifest found at $manifest."
    echo "Run bootstrap without --update first to create the manifest."
    echo "Alternatively, use --force to overwrite all files."
    return 1
  fi

  # Process each seed source
  local sources=("$seed_dir" "$preset_root/$preset/docs")
  local source_labels=("seed" "preset:$preset")

  for idx in 0 1; do
    local src_root="${sources[$idx]}"
    local label="${source_labels[$idx]}"

    if [[ ! -d "$src_root" ]]; then
      continue
    fi

    while IFS= read -r src; do
      local rel="${src#"$src_root"/}"
      local dest="$target/docs/$rel"
      local seed_hash
      seed_hash="$(shasum -a 256 "$src" | cut -d' ' -f1)"

      # Look up original hash from manifest
      local orig_hash
      orig_hash="$(awk -v path="$rel" '$2 == path { print $1; exit }' "$manifest")"

      # Current file hash (if exists)
      local curr_hash=""
      if [[ -f "$dest" ]]; then
        curr_hash="$(shasum -a 256 "$dest" | cut -d' ' -f1)"
      fi

      # Decision logic
      if [[ -z "$curr_hash" ]]; then
        # New file — doesn't exist in project
        if [[ "$dry_run" -eq 1 ]]; then
          echo "  + ADD [$label] docs/$rel (new file)"
        else
          mkdir -p "$(dirname "$dest")"
          cp "$src" "$dest"
          echo "  + ADDED [$label] docs/$rel"
        fi
        added=$((added + 1))

      elif [[ "$seed_hash" == "$curr_hash" ]]; then
        # Seed matches current — no one changed anything
        unchanged=$((unchanged + 1))

      elif [[ "$seed_hash" == "$orig_hash" && -n "$orig_hash" ]]; then
        # Seed unchanged, but current differs → user customized
        preserved=$((preserved + 1))
        echo "  ~ PRESERVE [$label] docs/$rel (user modified)"

      elif [[ "$seed_hash" != "$orig_hash" && "$curr_hash" == "$orig_hash" ]]; then
        # Seed changed, current matches original → safe to update
        if [[ "$dry_run" -eq 1 ]]; then
          echo "  ↑ UPDATE [$label] docs/$rel (seed changed)"
        else
          cp "$src" "$dest"
          echo "  ↑ UPDATED [$label] docs/$rel"
        fi
        updated=$((updated + 1))

      else
        # Both changed — conflict
        conflicts=$((conflicts + 1))
        echo "  ✗ CONFLICT [$label] docs/$rel (both seed and user modified)"
        if [[ "$force" -eq 1 ]]; then
          if [[ "$dry_run" -eq 1 ]]; then
            echo "    → would overwrite (--force)"
          else
            cp "$src" "$dest"
            echo "    → overwritten (--force)"
            updated=$((updated + 1))
            conflicts=$((conflicts - 1))
          fi
        fi
      fi
    done < <(find "$src_root" -type f | sort)
  done

  echo ""
  echo "=== Update Summary ==="
  echo "Added: $added"
  echo "Updated: $updated"
  echo "Preserved (user modified): $preserved"
  echo "Conflicts: $conflicts"
  echo "Unchanged: $unchanged"
  echo ""

  # Regenerate manifest after update
  if [[ "$dry_run" -eq 0 && $((added + updated)) -gt 0 ]]; then
    generate_manifest "$target"
    echo "Manifest regenerated at $manifest"
  fi

  if [[ "$conflicts" -gt 0 ]]; then
    echo "⚠️  $conflicts conflict(s) detected. Review and resolve manually, or re-run with --force."
    return 1
  fi

  echo "✅ Incremental update complete."
  return 0
}

# Handle --update mode: incremental update instead of full bootstrap
if [[ "$update" -eq 1 ]]; then
  update_docs "$target_dir"
  exit $?
fi

copy_tree "$seed_dir" "$target_dir/docs"
copy_tree "$preset_root/$preset/docs" "$target_dir/docs"

# Create project memory structure (docs/.memory/shared/ and docs/.memory/local/).
init_memory_structure() {
  local target="$1"
  local dry="$2"
  local mem_dir="$target/docs/.memory"
  local status="created"

  if [[ -d "$mem_dir/shared" && -d "$mem_dir/local" ]]; then
    echo "exists"
    return
  fi

  if [[ "$dry" -eq 1 ]]; then
    echo "create (dry-run)"
    return
  fi

  mkdir -p "$mem_dir/shared" "$mem_dir/local"

  # Create .gitignore entry for local/ if not present.
  local gitignore="$target/.gitignore"
  if [[ -f "$gitignore" ]]; then
    if ! grep -qF 'docs/.memory/local/' "$gitignore"; then
      printf '\n# Compass local memory (machine-specific, not committed)\ndocs/.memory/local/\n' >> "$gitignore"
    fi
  else
    printf '# Compass local memory (machine-specific, not committed)\ndocs/.memory/local/\n' > "$gitignore"
  fi

  # Create README if not present.
  if [[ ! -f "$mem_dir/README.md" ]]; then
    cat > "$mem_dir/README.md" <<'MEMREADME'
---
type: reference
status: active
summary: Project memory structure — shared (committed) and local (gitignored) knowledge
---

# Project Memory

Compass project memory is split into two scopes:

## shared/ (committed)

Team knowledge that benefits everyone: architecture decisions, coding conventions,
module relationships, testing patterns, API contracts, deployment rules.

These files are committed to the repository so all team members share the same
project context across sessions and IDEs.

## local/ (gitignored)

Machine-specific knowledge: tool paths, local ports, IDE config, OS workarounds,
personal preferences, credentials references.

These files are gitignored — they stay on your machine only.

## How memories are created

- Run `scripts/memory-sync.sh` to import memories from other agents (Claude Code, Qoder, Cursor).
- The agent classifies each memory automatically based on content keywords.
- Ambiguous memories are placed in shared/ with a review note.
MEMREADME
    status="created"
  fi

  echo "$status"
}

# Generate manifest for future incremental updates
if [[ "$update" -eq 0 ]]; then
  generate_manifest "$target_dir"
fi

memory_status="$(init_memory_structure "$target_dir" "$dry_run")"

agents_status="skipped"
if [[ "$skip_agents" -ne 1 ]]; then
  agents_status="$(detect_and_write_gateways "$target_dir" "$dry_run" "$agents_files_override")"
fi

echo "Compass docs bootstrap complete: created=$created skipped=$skipped overwritten=$overwritten preset=$preset force=$force dry_run=$dry_run memory=$memory_status agents=$agents_status"
echo "Compass docs bootstrap workflow: docs/process/workflows.xml from preset=$preset"
echo "Compass docs bootstrap note: the LLM must adapt copied preset docs to the target language/framework before treating docs as ready."
echo "Compass docs bootstrap note: the LLM must adapt the agent gateway Compass block to the project context before treating docs as ready."

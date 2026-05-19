#!/usr/bin/env bash
set -euo pipefail

target_dir="$(pwd)"
force=0
dry_run=0
preset=""

usage() {
  cat <<'USAGE'
Usage: bootstrap-docs.sh [--target DIR] --preset NAME [--force] [--dry-run]
       bootstrap-docs.sh --list-presets

Copy Compass seed documentation, orientation lock, and preset process docs into DIR.

Options:
  --target DIR    Project directory to seed. Defaults to current directory.
  --preset NAME   Orientation preset to apply. Required unless --list-presets is used.
  --force         Overwrite existing files.
  --dry-run       Print planned actions without writing files.
  --list-presets  Print available orientation presets with short descriptions.
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
PRESETS
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
    --dry-run)
      dry_run=1
      shift
      ;;
    --list-presets)
      list_presets
      exit 0
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

copy_tree "$seed_dir" "$target_dir/docs"
copy_tree "$preset_root/$preset/docs" "$target_dir/docs"

echo "Compass docs bootstrap complete: created=$created skipped=$skipped overwritten=$overwritten preset=$preset force=$force dry_run=$dry_run"
echo "Compass docs bootstrap workflow: docs/process/workflows.xml from preset=$preset"
echo "Compass docs bootstrap note: the LLM must adapt copied preset docs to the target language/framework before treating docs as ready."

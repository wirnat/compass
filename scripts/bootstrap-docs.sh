#!/usr/bin/env bash
set -euo pipefail

target_dir="$(pwd)"
force=0
dry_run=0

usage() {
  cat <<'USAGE'
Usage: bootstrap-docs.sh [--target DIR] [--force] [--dry-run]

Copy Compass seed documentation into DIR/docs.

Options:
  --target DIR  Project directory to seed. Defaults to current directory.
  --force       Overwrite existing files.
  --dry-run     Print planned actions without writing files.
USAGE
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
    --force)
      force=1
      shift
      ;;
    --dry-run)
      dry_run=1
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

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
seed_dir="$(cd "$script_dir/../assets/docs-seed" && pwd)"
target_dir="$(cd "$target_dir" && pwd)"
dest_dir="$target_dir/docs"

created=0
skipped=0
overwritten=0

while IFS= read -r dir; do
  rel="${dir#"$seed_dir"}"
  [[ -z "$rel" ]] && continue
  if [[ "$dry_run" -eq 1 ]]; then
    if [[ ! -d "$dest_dir$rel" ]]; then
      echo "mkdir $dest_dir$rel"
    fi
  else
    mkdir -p "$dest_dir$rel"
  fi
done < <(find "$seed_dir" -type d | sort)

while IFS= read -r src; do
  rel="${src#"$seed_dir"/}"
  dest="$dest_dir/$rel"

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
done < <(find "$seed_dir" -type f | sort)

echo "Compass docs bootstrap complete: created=$created skipped=$skipped overwritten=$overwritten force=$force dry_run=$dry_run"

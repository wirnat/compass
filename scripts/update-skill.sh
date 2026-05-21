#!/usr/bin/env bash
set -euo pipefail

repo_url="${COMPASS_REPO_URL:-https://github.com/wirnat/compass.git}"
branch="${COMPASS_REPO_BRANCH:-main}"
skill_dir=""
check_only=0
force=0

usage() {
  cat <<'USAGE'
Usage: update-skill.sh [--skill-dir DIR] [--repo-url URL] [--branch NAME] [--check] [--force]

Check whether an installed Compass skill matches the latest Git revision and,
unless --check is used, update the installed skill from the remote repository.

Options:
  --skill-dir DIR  Installed Compass skill directory. Defaults to the parent of this script.
  --repo-url URL   Git repository URL. Defaults to https://github.com/wirnat/compass.git.
  --branch NAME    Git branch to track. Defaults to main.
  --check          Only report local and remote revisions.
  --force          Allow update even when a git-backed skill directory has local changes.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill-dir)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --skill-dir" >&2
        exit 2
      fi
      skill_dir="$2"
      shift 2
      ;;
    --repo-url)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --repo-url" >&2
        exit 2
      fi
      repo_url="$2"
      shift 2
      ;;
    --branch)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --branch" >&2
        exit 2
      fi
      branch="$2"
      shift 2
      ;;
    --check)
      check_only=1
      shift
      ;;
    --force)
      force=1
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

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 127
  fi
}

need_cmd git
need_cmd mktemp
need_cmd cp
need_cmd rm

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "$skill_dir" ]]; then
  skill_dir="$(cd "$script_dir/.." && pwd)"
else
  skill_dir="$(cd "$skill_dir" && pwd)"
fi

if [[ ! -f "$skill_dir/SKILL.md" ]]; then
  echo "not a Compass skill directory: $skill_dir" >&2
  exit 2
fi

remote_rev="$(git ls-remote "$repo_url" "refs/heads/$branch" | awk 'NR == 1 { print $1 }')"
if [[ -z "$remote_rev" ]]; then
  echo "unable to read remote revision: $repo_url refs/heads/$branch" >&2
  exit 1
fi

local_rev="unknown"
metadata_file="$skill_dir/.compass-source-revision"

if [[ -d "$skill_dir/.git" ]]; then
  local_rev="$(git -C "$skill_dir" rev-parse HEAD 2>/dev/null || echo unknown)"
elif [[ -f "$metadata_file" ]]; then
  local_rev="$(awk -F= '$1 == "revision" { print $2; exit }' "$metadata_file")"
  [[ -n "$local_rev" ]] || local_rev="unknown"
fi

if [[ "$local_rev" == "$remote_rev" ]]; then
  echo "Compass skill up to date: $local_rev"
  exit 0
fi

echo "Compass skill update available: local=$local_rev remote=$remote_rev repo=$repo_url branch=$branch"

if [[ "$check_only" -eq 1 ]]; then
  exit 0
fi

if [[ -d "$skill_dir/.git" ]]; then
  if [[ "$force" -ne 1 ]]; then
    if ! git -C "$skill_dir" diff --quiet || ! git -C "$skill_dir" diff --cached --quiet; then
      echo "refusing to update git-backed skill with local changes: $skill_dir" >&2
      echo "commit, stash, or rerun with --force if replacing local changes is intentional" >&2
      exit 3
    fi
  fi

  git -C "$skill_dir" fetch --quiet "$repo_url" "refs/heads/$branch"
  git -C "$skill_dir" reset --quiet --hard FETCH_HEAD
  resolved_rev="$(git -C "$skill_dir" rev-parse HEAD)"
else
  tmp_dir="$(mktemp -d)"
  cleanup() {
    rm -rf "$tmp_dir"
  }
  trap cleanup EXIT

  git clone --quiet --depth 1 --branch "$branch" "$repo_url" "$tmp_dir/source"
  resolved_rev="$(git -C "$tmp_dir/source" rev-parse HEAD)"

  paths=(
    SKILL.md
    README.md
    agents
    assets
    docs
    references
    scripts
  )

  for item in "${paths[@]}"; do
    if [[ -e "$tmp_dir/source/$item" ]]; then
      rm -rf "$skill_dir/$item"
      cp -R "$tmp_dir/source/$item" "$skill_dir/$item"
    fi
  done
fi

cat > "$metadata_file" <<META
revision=$resolved_rev
repo_url=$repo_url
branch=$branch
updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
META

echo "Compass skill updated: local=$local_rev remote=$resolved_rev skill_dir=$skill_dir"
echo "Reload Compass instructions from $skill_dir/SKILL.md before continuing."

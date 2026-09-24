#!/usr/bin/env bash
set -euo pipefail

repo_url="${COMPASS_REPO_URL:-https://github.com/wirnat/compass.git}"
branch="${COMPASS_REPO_BRANCH:-main}"
tag=""
skill_dir=""
check_only=0
force=0

usage() {
  cat <<'USAGE'
Usage: update-skill.sh [--skill-dir DIR] [--repo-url URL] [--branch NAME] [--tag TAG] [--check] [--force]

Check whether an installed Compass skill matches the latest revision and,
unless --check is used, update the installed skill from the remote repository.

By default, tracks the main branch (bleeding edge). Use --tag to follow
stable releases instead:
  --tag latest   Track the latest release tag
  --tag v1.2.3   Pin to a specific version

Options:
  --skill-dir DIR  Installed Compass skill directory. Defaults to the parent of this script.
  --repo-url URL   Git repository URL. Defaults to https://github.com/wirnat/compass.git.
  --branch NAME    Git branch to track. Defaults to main. Ignored if --tag is set.
  --tag TAG        Release tag to track. Use 'latest' or a specific version like 'v1.2.3'.
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
    --tag)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --tag" >&2
        exit 2
      fi
      tag="$2"
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

# --- Resolve target ref (branch or tag) ---

resolve_latest_tag() {
  # Fetch latest release tag from GitHub API or git ls-remote
  local repo_path
  # Extract owner/repo from URL (supports https and git@ formats)
  repo_path="$(echo "$repo_url" | sed -E 's#.*github\.com[:/]([^/]+/[^/.]+).*#\1#')"

  if command -v curl >/dev/null 2>&1; then
    local api_response
    api_response="$(curl -sS "https://api.github.com/repos/$repo_path/releases/latest" 2>/dev/null || true)"
    if [[ -n "$api_response" ]]; then
      # Extract tag_name from JSON (simple grep, no jq dependency)
      echo "$api_response" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
      return
    fi
  fi

  # Fallback: use git ls-remote to find the latest tag
  git ls-remote --tags --refs "$repo_url" 2>/dev/null \
    | awk -F/ '{ print $NF }' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -t. -k1,1nr -k2,2nr -k3,3nr \
    | head -1
}

ref_type="branch"
ref_name="$branch"
remote_version=""

if [[ -n "$tag" ]]; then
  ref_type="tag"
  if [[ "$tag" == "latest" ]]; then
    ref_name="$(resolve_latest_tag)"
    if [[ -z "$ref_name" ]]; then
      echo "unable to resolve latest tag from $repo_url" >&2
      exit 1
    fi
    remote_version="$ref_name"
  else
    ref_name="$tag"
    remote_version="$tag"
  fi

  # Resolve tag to commit SHA
  remote_rev="$(git ls-remote "$repo_url" "refs/tags/$ref_name" | awk 'NR == 1 { print $1 }')"
  if [[ -z "$remote_rev" ]]; then
    echo "unable to read remote revision for tag $ref_name: $repo_url" >&2
    exit 1
  fi
else
  remote_rev="$(git ls-remote "$repo_url" "refs/heads/$branch" | awk 'NR == 1 { print $1 }')"
  if [[ -z "$remote_rev" ]]; then
    echo "unable to read remote revision: $repo_url refs/heads/$branch" >&2
    exit 1
  fi
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
  if [[ -n "$remote_version" ]]; then
    echo "Compass skill up to date: $remote_version ($local_rev)"
  else
    echo "Compass skill up to date: $local_rev"
  fi
  exit 0
fi

if [[ -n "$remote_version" ]]; then
  echo "Compass skill update available: $remote_version (local=$local_rev remote=$remote_rev ref=$ref_type/$ref_name)"
else
  echo "Compass skill update available: local=$local_rev remote=$remote_rev ref=$ref_type/$ref_name"
fi

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

  if [[ "$ref_type" == "tag" ]]; then
    git -C "$skill_dir" fetch --quiet "$repo_url" "refs/tags/$ref_name"
    git -C "$skill_dir" reset --quiet --hard FETCH_HEAD
  else
    git -C "$skill_dir" fetch --quiet "$repo_url" "refs/heads/$branch"
    git -C "$skill_dir" reset --quiet --hard FETCH_HEAD
  fi
  resolved_rev="$(git -C "$skill_dir" rev-parse HEAD)"
else
  tmp_dir="$(mktemp -d)"
  cleanup() {
    rm -rf "$tmp_dir"
  }
  trap cleanup EXIT

  if [[ "$ref_type" == "tag" ]]; then
    git clone --quiet --depth 1 --branch "$ref_name" "$repo_url" "$tmp_dir/source"
  else
    git clone --quiet --depth 1 --branch "$branch" "$repo_url" "$tmp_dir/source"
  fi
  resolved_rev="$(git -C "$tmp_dir/source" rev-parse HEAD)"

  paths=(
    SKILL.md
    README.md
    VERSION
    CHANGELOG.md
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
ref_type=$ref_type
ref_name=$ref_name
branch=$branch
version=${remote_version:-}
updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
META

if [[ -n "$remote_version" ]]; then
  echo "Compass skill updated to $remote_version: local=$local_rev remote=$resolved_rev skill_dir=$skill_dir"
else
  echo "Compass skill updated: local=$local_rev remote=$resolved_rev skill_dir=$skill_dir"
fi
echo "Reload Compass instructions from $skill_dir/SKILL.md before continuing."

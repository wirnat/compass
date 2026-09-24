#!/usr/bin/env bash
# scripts/version.sh — Version management for Compass
# Usage:
#   ./scripts/version.sh              # Show current version
#   ./scripts/version.sh bump <type>  # Bump version (major, minor, patch)
#   ./scripts/version.sh tag          # Create git tag for current version

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"

# --- Helpers ---

die() { echo "ERROR: $*" >&2; exit 1; }

read_version() {
  [[ -f "$VERSION_FILE" ]] || die "VERSION file not found: $VERSION_FILE"
  tr -d '[:space:]' < "$VERSION_FILE"
}

write_version() {
  echo "$1" > "$VERSION_FILE"
}

validate_semver() {
  echo "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || die "Invalid semver: $1"
}

# --- Commands ---

cmd_show() {
  read_version
}

cmd_bump() {
  local type="${1:-}"
  [[ -n "$type" ]] || die "Usage: $0 bump <major|minor|patch>"

  local current
  current="$(read_version)"
  validate_semver "$current"

  local major minor patch
  IFS='.' read -r major minor patch <<< "$current"

  case "$type" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      die "Unknown bump type: $type (use major, minor, or patch)"
      ;;
  esac

  local new_version="$major.$minor.$patch"
  write_version "$new_version"
  echo "Bumped: $current -> $new_version"
  echo ""
  echo "Next steps:"
  echo "  git add VERSION"
  echo "  git commit -m \"chore: bump version to $new_version\""
  echo "  git tag v$new_version"
  echo "  git push origin main --tags"
}

cmd_tag() {
  local version
  version="$(read_version)"
  validate_semver "$version"

  local tag="v$version"

  # Check if tag already exists
  if git rev-parse "$tag" >/dev/null 2>&1; then
    die "Tag $tag already exists"
  fi

  # Check for uncommitted changes
  if ! git diff --quiet HEAD 2>/dev/null; then
    die "Uncommitted changes detected. Commit first."
  fi

  git tag -a "$tag" -m "Release $tag"
  echo "Created tag: $tag"
  echo ""
  echo "Push with:"
  echo "  git push origin main --tags"
}

# --- Main ---

case "${1:-show}" in
  show)
    cmd_show
    ;;
  bump)
    cmd_bump "${2:-}"
    ;;
  tag)
    cmd_tag
    ;;
  -h|--help|help)
    echo "Usage:"
    echo "  $0              Show current version"
    echo "  $0 bump <type>  Bump version (major, minor, patch)"
    echo "  $0 tag          Create git tag for current version"
    ;;
  *)
    die "Unknown command: $1 (use show, bump, or tag)"
    ;;
esac

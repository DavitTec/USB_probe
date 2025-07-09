#!/bin/bash
# release.sh
# Version: 0.2.3
# Purpose: Manage release process with version bump and changelog update

# Resolve script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/../.env" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/../.env"
else
  echo "ERROR: .env file not found in $SCRIPT_DIR/.."
  exit 1
fi

# Load logging script
if [ -f "$SCRIPT_DIR/logging.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/logging.sh"
else
  echo "ERROR: logging.sh script not found."
  exit 1
fi

# if [ "$(id -u)" != "0" ]; then
#   log "ERROR: This script must be run as root (sudo)."
#   exit 1
# fi

release() {
  local choice release_type temp_changelog
  # Check for modified or staged changes
  if [ -n "$(git status --porcelain)" ]; then
    log "Changes detected. Staging and committing with commitizen..."
    pnpm cz || {
      log "ERROR: Commitizen failed."
      exit 1
    }
  else
    log "No changes to commit. Proceeding with changelog update..."
  fi

  log "Select release type: (1) patch, (2) minor, (3) major"
  read -rp "Enter choice [1-3]: " choice
  case "$choice" in
  1) release_type="patch" ;;
  2) release_type="minor" ;;
  3) release_type="major" ;;
  *)
    log "ERROR: Invalid choice"
    exit 1
    ;;
  esac

  # Ensure clean working directory before version bump
  if [ -n "$(git status --porcelain)" ]; then
    log "ERROR: Git working directory not clean before version bump. Please commit or stash changes."
    git status
    exit 1
  fi

  # Bump version
  pnpm version "$release_type" || {
    log "ERROR: Version bump failed."
    exit 1
  }

  # Fetch latest tags
  git fetch --tags

  # Generate changelog
  temp_changelog=$(mktemp)
  log "Generating changelog to $temp_changelog..."
  if ! conventional-changelog -p angular -r 0 --outfile "$temp_changelog"; then
    log "ERROR: Changelog generation failed. Restoring previous CHANGELOG.md..."
    git checkout -- CHANGELOG.md
    rm -f "$temp_changelog"
    exit 1
  fi

  # Replace asterisks with dashes
  sed -i -E 's/^\* ([^\*])/- \1/g' "$temp_changelog"
  sed -i -E 's/^\* \*\*([^\*]+)\*\*/- \*\*\1\*\*/g' "$temp_changelog"

  # Update changelog
  echo -e "# CHANGELOG\n\n" >CHANGELOG.md
  cat "$temp_changelog" >>CHANGELOG.md
  rm -f "$temp_changelog"

  # Format Markdown files to ensure consistency
  log "Running markdownlint to fix formatting..."
  pnpm format || {
    log "ERROR: Markdown formatting failed."
    exit 1
  }

  # Commit changelog if changed
  if git diff --quiet CHANGELOG.md; then
    log "No changes to CHANGELOG.md, skipping commit..."
  else
    git add CHANGELOG.md
    HUSKY=0 git commit -m "chore(release): update changelog"
  fi

  git push --follow-tags
  log "Release $release_type completed!"
}

release

# end of script

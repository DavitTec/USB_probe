#!/bin/bash
# release.sh
# Version: 0.2.14
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

release() {
  local choice release_type
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

  # Bump version and create tag
  pnpm version "$release_type" || {
    log "ERROR: Version bump failed."
    exit 1
  }

  # Fetch latest tags
  git fetch --tags --force

  # Generate changelog
  log "Generating changelog..."
  if ! pnpm changelog:first; then
    log "ERROR: Changelog generation failed. Restoring previous CHANGELOG.md..."
    git checkout -- CHANGELOG.md
    exit 1
  fi

  # Fix changelog formatting
  pnpm changelog:fix || {
    log "ERROR: Changelog fix failed."
    exit 1
  }

  # Update markdownlint config
  log "Updating markdownlint config..."
  cat >.markdownlint.json <<EOL
{
  "default": true,
  "MD025": { "level": 2 },
  "MD001": false,
  "MD003": { "style": "atx" },
  "MD004": { "style": "dash" },
  "MD007": { "indent": 2 },
  "MD013": { "line_length": 150 },
  "MD024": false,
  "MD031": true,
  "MD032": true,
  "MD046": { "style": "fenced" },
  "no-hard-tabs": false,
  "whitespace": false
}
EOL

  pnpm format || {
    log "ERROR: Formatting failed."
    exit 1
  }

  # Validate commit URLs
  log "Validating commit URLs..."
  grep -o 'https://github.com/DavitTec/usb_probe/commit/[^)]*' CHANGELOG.md | while read -r url; do
    if curl --output /dev/null --silent --head --fail "$url"; then
      log "URL valid: $url"
    else
      log "ERROR: Commit URL invalid: $url"
      exit 1
    fi
  done

  # Commit changelog and config if changed
  if git diff --quiet CHANGELOG.md .markdownlint.json; then
    log "No changes to CHANGELOG.md or .markdownlint.json, skipping commit..."
  else
    git add CHANGELOG.md .markdownlint.json
    git commit -m "chore(release): update changelog and markdownlint config"
  fi

  # Push changes and tags
  git push origin master
  git push origin --tags
  log "Release $release_type completed!"
}

release

# End of script

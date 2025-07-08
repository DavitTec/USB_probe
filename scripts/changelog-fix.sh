#!/bin/bash
# changelog-fix.sh
# Version: 0.2.1
# Purpose: Modify header of CHANGELOG.md and update version

# Load environment variables
if [ -f "./.env" ]; then
  # shellcheck disable=SC1091
  source "./.env"
else
  echo "ERROR: .env file not found."
  exit 1
fi

# Load logging script
if [ -f "./scripts/logging.sh" ]; then
  # shellcheck disable=SC1091
  source "./scripts/logging.sh"
else
  echo "ERROR: logging.sh script not found."
  exit 1
fi

# if [ "$(id -u)" != "0" ]; then
#   log "ERROR: This script must be run as root (sudo)."
#   exit 1
# fi

update_changelog() {
  local temp_changelog
  #temp_changelog=$(mktemp)
  temp_changelog="change1.tmp"
  log "Generating changelog to $temp_changelog..."
  # Ensure conventional-changelog is installed
  if ! { conventional-changelog -p angular -i CHANGELOG.md --outfile "$temp_changelog"; }; then
    log "ERROR: Failed to generate changelog."
    rm -f "$temp_changelog"
    exit 1
  fi
  echo -e "# Changelog\n\n" >CHANGELOG.md
  cat "$temp_changelog" >>CHANGELOG.md
  rm -f "$temp_changelog"
  log "Updated CHANGELOG.md."
  git add CHANGELOG.md
  HUSKY=0 git commit -m "chore(release): update changelog"
  pnpm version patch
  git push --follow-tags
}

update_changelog

# end of script

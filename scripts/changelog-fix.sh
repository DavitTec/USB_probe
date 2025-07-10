#!/bin/bash
# changelog-fix.sh
# Version: 0.2.5
# Purpose: Format CHANGELOG.md and replace comparison URLs with release pages

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

# Check if CHANGELOG.md exists
if [ ! -f "CHANGELOG.md" ]; then
  log "ERROR: CHANGELOG.md not found."
  exit 1
fi

# Fix changelog formatting
log "Fixing CHANGELOG.md formatting..."
sed -i -E 's/^\* ([^\*])/- \1/g' CHANGELOG.md
sed -i -E 's/^\* \*\*([^\*]+)\*\*/- \*\*\1\*\*/g' CHANGELOG.md

# Replace comparison URLs with release pages
log "Replacing comparison URLs with release pages..."
sed -i 's|https://github.com/DavitTec/USB_probe/compare/\([^)]*\)|https://github.com/DavitTec/USB_probe/releases/tag/\1|g' CHANGELOG.md

# Run prettier to format
pnpm run prettier --write CHANGELOG.md || {
  log "ERROR: Prettier formatting failed."
  exit 1
}

log "Changelog formatting complete."

# End of script

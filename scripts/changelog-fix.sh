#!/bin/bash
# changelog-fix.sh
# Version: 0.2.9
# Purpose: Format CHANGELOG.md and ensure correct headers

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
# Ensure single h1 header and h2 for versions
sed -i -E 's/^# \[(.*)\]\((.*)\)/## [\1](\2)/g' CHANGELOG.md
sed -i '1s/^/# CHANGELOG\n\n/' CHANGELOG.md
# Remove duplicate h1 headers
sed -i '/^# CHANGELOG/{2,$d}' CHANGELOG.md

# Run format
pnpm format || {
  log "ERROR: Formatting failed."
  exit 1
}

# Validate commit URLs
log "Validating commit URLs..."
grep -o 'https://github.com/DavitTec/usb_probe/commit/[^)]*' CHANGELOG.md | while read -r url; do
  if curl --output /dev/null --silent --head --fail "$url"; then
    echo "URL valid: $url"
  else
    log "ERROR: Commit URL invalid: $url"
    exit 1
  fi
done

log "Changelog formatting complete."

# End of script

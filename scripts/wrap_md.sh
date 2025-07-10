#!/bin/bash
# wrap_md.sh
# Version: 0.0.1
# Purpose: Pre-setup markdownlint for the project to ensure consistent markdown formatting
# set MAX_LINE_LENGTH in .env or defaults to 120

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/../.env" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/../.env"
else
  echo "ERROR: .env file not found in $SCRIPT_DIR/.."
  exit 1
fi

MAX_LINE_LENGTH=${MAX_LINE_LENGTH:-120}

# Fix other Markdown files in docs/
for file in docs/*.md; do
  if [ -f "$file" ]; then
    log "Wrapping lines in $file to $MAX_LINE_LENGTH characters..."
    fold -s -w "$MAX_LINE_LENGTH" "$file" >"${file}.tmp"
    mv "${file}.tmp" "$file"
  fi
done

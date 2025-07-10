#!/bin/bash
# wrap_md.sh
# Version: 0.0.4
# Purpose: Wrap prose lines in Markdown files to MAX_LINE_LENGTH while preserving tables, URLs, and code blocks
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

# Ensure Python is available
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Python3 is required but not installed."
  exit 1
fi

# Create temporary Python script for wrapping
cat >/tmp/wrap_md.py <<'EOF'
import re
import textwrap
import sys
import os

# Get MAX_LINE_LENGTH from environment
max_length = int(os.getenv("MAX_LINE_LENGTH", 120))

# Read input file
with open(sys.argv[1], "r") as f:
    lines = f.readlines()

output = []
in_code_block = False
for line in lines:
    line = line.rstrip()
    # Toggle code block state
    if line.strip().startswith("```"):
        in_code_block = not in_code_block
        output.append(line)
        continue
    # Skip tables, URLs, and code blocks
    if in_code_block or line.strip().startswith("|") or ":-:" in line or "http://" in line or "https://" in line:
        output.append(line)
    else:
        # Wrap prose lines
        wrapped = textwrap.wrap(line, width=max_length, break_long_words=False, break_on_hyphens=False)
        output.extend(wrapped if wrapped else [line])
with open(sys.argv[1], "w") as f:
    f.write("\n".join(output) + "\n")
EOF

# Process Markdown files
for file in CHANGELOG.md docs/*.md; do
  if [ -f "$file" ]; then
    echo "Wrapping lines in $file to $MAX_LINE_LENGTH characters..."
    python3 /tmp/wrap_md.py "$file" || {
      echo "ERROR: Failed to wrap lines in $file"
      exit 1
    }
  fi
done

# Clean up
rm -f /tmp/wrap_md.py

echo "Markdown line wrapping complete."

# end of script

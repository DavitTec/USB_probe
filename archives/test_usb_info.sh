#!/bin/bash
# test_usb_info.sh
# Test cases for usb_info.sh

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

# Test 1: Check dependencies
echo "Testing dependencies..."
if ! command -v jq >/dev/null 2>&1 || ! command -v lsblk >/dev/null 2>&1 || ! command -v lsusb >/dev/null 2>&1 || ! command -v blkid >/dev/null 2>&1; then
  echo "ERROR: Missing dependencies"
  exit 1
fi

# Test 2: Run script with no USBs
echo "Testing with no USBs..."
# shellcheck disable=SC2024
sudo bash "$SCRIPT_DIR/../scripts/usb_info.sh" </dev/null >"$LOG_DIR/test_output.log" 2>&1
if grep -q "No pendrives detected" "$LOG_DIR/usb_script.log"; then
  echo "Test passed: No pendrives detected"
else
  echo "Test failed: Expected no pendrives"
  cat "$LOG_DIR/usb_script.log"
  exit 1
fi

echo "All tests passed!"
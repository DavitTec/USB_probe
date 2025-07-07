#!/bin/bash
# test_usb_info.sh
# version 0.2
# Minimal test cases for usb_info.sh

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
missing=()
for cmd in jq lsblk lsusb blkid; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("$cmd")
  fi
done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "ERROR: Missing dependencies: ${missing[*]}"
  exit 1
fi
echo "Test passed: All dependencies present"

# Test 2: Run script with no USBs
echo "Testing with no USBs..."
# shellcheck disable=SC2024
echo -e "\n" | sudo bash "$SCRIPT_DIR/../scripts/usb_info.sh" >"$LOG_DIR/test_output.log" 2>&1
if grep -q "No pendrives detected" "$LOG_DIR/usb_script.log"; then
  echo "Test passed: No pendrives detected"
else
  echo "Test failed: Expected no pendrives"
  cat "$LOG_DIR/usb_script.log"
  exit 1
fi

# Test 3: Check pendrive detection
echo "Testing pendrive detection..."
echo -e "\nsdb\n" | sudo bash "$SCRIPT_DIR/../scripts/usb_info.sh" >"$LOG_DIR/test_output.log" 2>&1
if grep -q "User chose pendrive: sdb" "$LOG_DIR/usb_script.log"; then
  echo "Test passed: Pendrive detected"
else
  echo "Test failed: Expected pendrive sdb"
  cat "$LOG_DIR/usb_script.log"
  exit 1
fi

echo "All tests passed!"
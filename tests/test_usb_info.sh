#!/bin/bash
# test_usb_info.sh
# version 0.5
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

# Logging function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >>"$LOG_DIR/test.log"
}

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
  log "ERROR: Missing dependencies: ${missing[*]}"
  exit 1
fi
echo "Test passed: All dependencies present"
log "Test passed: Dependencies check"

# Test 2: Check lsblk output with no USBs
echo "Testing lsblk output with no USBs..."
echo "Please remove all USB pendrives and press Enter..."
read -r
# shellcheck disable=SC2024
sudo bash "$SCRIPT_DIR/../scripts/usb_info.sh" >"$LOG_DIR/test_output.log" 2>&1
if grep -q "No USB pendrives detected" "$LOG_DIR/usb_script.log"; then
  echo "Test passed: No pendrives detected"
  log "Test passed: No pendrives detected"
else
  echo "Test failed: Expected no pendrives"
  cat "$LOG_DIR/usb_script.log"
  cat "$LOG_DIR/test_output.log"
  log "Test failed: Expected no pendrives"
  exit 1
fi

# Test 3: Check pendrive detection
echo "Testing pendrive detection..."
echo "Please attach a USB pendrive and press Enter..."
read -r
# shellcheck disable=SC2024
sudo bash "$SCRIPT_DIR/../scripts/usb_info.sh" >"$LOG_DIR/test_output.log" 2>&1
if grep -q "User chose pendrive: sdb" "$LOG_DIR/usb_script.log"; then
  echo "Test passed: Pendrive sdb detected"
  log "Test passed: Pendrive sdb detected"
else
  echo "Test failed: Expected pendrive sdb"
  cat "$LOG_DIR/usb_script.log"
  cat "$LOG_DIR/test_output.log"
  log "Test failed: Expected pendrive sdb"
  exit 1
fi

# Test 4: Check USB_Registry.json creation
echo "Testing USB_Registry.json creation..."
if [[ -f "$REGISTRY_DIR/USB_Registry.json" && -f "/media/david/BOOT/USB_Registry.json" ]]; then
  echo "Test passed: USB_Registry.json created"
  log "Test passed: USB_Registry.json created"
else
  echo "Test failed: USB_Registry.json not created"
  log "Test failed: USB_Registry.json not created"
  exit 1
fi

# Test 5: Compare lsblk outputs
echo "Testing lsblk output comparison..."
if [[ -f "$LOG_DIR/lsblk_output_none.json" && -f "$LOG_DIR/lsblk_output_TEST1.json" ]]; then
  diff_output=$(diff "$LOG_DIR/lsblk_output_none.json" "$LOG_DIR/lsblk_output_TEST1.json")
  if [[ -n "$diff_output" ]]; then
    echo "Test passed: Differences found between lsblk outputs"
    echo "$diff_output"
    log "Test passed: lsblk diff: $diff_output"
  else
    echo "Test failed: No differences found"
    log "Test failed: No differences found"
    exit 1
  fi
else
  echo "Test failed: lsblk output files missing"
  log "Test failed: lsblk output files missing"
  exit 1
fi

echo "All tests passed!"
log "All tests passed"

# End of script

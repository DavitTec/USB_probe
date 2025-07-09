#!/bin/bash
# test_usb_simple.sh
# version 0.6
# Detects attachment status of sd[a-f] devices and USB protocol without user prompts
# Requires sudo for lsblk, usb-devices, and file operations

# Devices
STORAGE_DEVICES=("sda" "sdb" "sdc" "sdd" "sde" "sdf")

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

# Get $USER from environment variables
USER="${USER:-$(whoami)}"

# Define files
LOG_FILE="$LOG_DIR/test_usb_simple.log"
OUTPUT_JSON="$LOG_DIR/usb_registry.json"
REGISTRY_JSON="$REGISTRY_DIR/usb_registry.json"

# Create log and registry directories
for dir in "$LOG_DIR" "$REGISTRY_DIR"; do
  if [ ! -d "$dir" ]; then
    if ! mkdir -p "$dir"; then
      echo "ERROR: Cannot create directory $dir"
      exit 1
    fi
    if ! chmod 775 "$dir"; then
      echo "ERROR: Cannot set permissions on $dir"
      exit 1
    fi
    if ! chown "$USER:$USER" "$dir"; then
      echo "ERROR: Cannot set ownership on $dir"
      exit 1
    fi
  fi
done

# Ensure log file is writable
if [ -f "$LOG_FILE" ]; then
  if ! chmod 664 "$LOG_FILE" 2>/dev/null; then
    echo "ERROR: Cannot set permissions on $LOG_FILE"
    exit 1
  fi
else
  if ! touch "$LOG_FILE" 2>/dev/null; then
    echo "ERROR: Cannot create $LOG_FILE"
    exit 1
  fi
  if ! chmod 664 "$LOG_FILE" 2>/dev/null; then
    echo "ERROR: Cannot set permissions on $LOG_FILE"
    exit 1
  fi
fi
if ! chown "$USER:$USER" "$LOG_FILE" 2>/dev/null; then
  echo "ERROR: Cannot set ownership on $LOG_FILE"
  exit 1
fi

# Logging function
log() {
  local level="$1"
  local message="$2"
  if ! echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >>"$LOG_FILE" 2>/dev/null; then
    echo "ERROR: Cannot write to $LOG_FILE"
    exit 1
  fi
}

# Feedback function
feedback() {
  echo "$1"
}

# Check sudo
check_sudo() {
  if [[ $EUID -ne 0 ]]; then
    feedback "This script requires sudo privileges."
    echo "ERROR: Sudo privileges required"
    exit 1
  fi
  log "INFO" "Sudo check passed"
}

# Check dependencies
check_dependencies() {
  local missing=()
  for cmd in jq lsblk usb-devices; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    feedback "ERROR: Missing dependencies: ${missing[*]}"
    log "ERROR" "Missing dependencies: ${missing[*]}"
    exit 1
  fi
  log "INFO" "All dependencies present"
}

# Check if device is boot drive
check_boot_drive() {
  local device="$1"
  local mountpoint
  mountpoint=$(lsblk -J -o NAME,MOUNTPOINT 2>/dev/null | jq -r ".blockdevices[] | select(.name==\"$device\") | .children[]?.mountpoint // empty | select(. == \"/\" or . == \"/boot\" or . == \"/boot/efi\")")
  if [[ -n "$mountpoint" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Detect USB devices
detect_usb_devices() {
  feedback "Detecting USB devices..."
  log "INFO" "Starting USB device detection"
  local lsblk_output
  lsblk_output=$(lsblk -J -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT,UUID 2>/dev/null)
  if [[ -z "$lsblk_output" ]]; then
    feedback "ERROR: lsblk output is empty."
    log "ERROR" "lsblk output is empty"
    exit 1
  fi
  log "INFO" "lsblk output: $lsblk_output"
  local usb_info
  usb_info=$(usb-devices 2>/dev/null | grep -E 'T:  Bus=|P:  Vendor=058f')
  log "INFO" "USB info: $usb_info"
  local devices_json
  devices_json=$(printf '%s\n' "${STORAGE_DEVICES[@]}" | jq -R . | jq -s .)
  local slots=${#STORAGE_DEVICES[@]}
  local usb_status
  usb_status=$(echo "$lsblk_output" | jq -r --argjson devices "$devices_json" --arg slots "$slots" '
    . as $input | {
      "device": "usb_probe",
      "slots": ($slots | tonumber),
      "blockdevices": (
        [
          .blockdevices[] | select(.name | startswith("sd")) | {
            "name": .name,
            "attached": true,
            "size": .size,
            "fstype": .fstype,
            "label": .label,
            "mountpoint": .mountpoint,
            "uuid": .uuid,
            "children": (.children // [] | map(select(.type=="part") | {
              "name": .name,
              "size": .size,
              "fstype": .fstype,
              "label": .label,
              "mountpoint": .mountpoint,
              "uuid": .uuid
            }))
          }
        ] + (
          $devices | map(
            select(. as $name | [$input.blockdevices[].name] | index($name) | not)
          ) | map({ "name": ., "attached": false })
        ) | sort_by(.name)
      )
    }')
  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    # shellcheck disable=SC2319
    feedback "ERROR: Failed to parse lsblk output with jq: $?"
    log "ERROR" "Failed to parse lsblk output: $lsblk_output"
    exit 1
  fi
  if [[ -z "$usb_status" ]]; then
    feedback "ERROR: No USB status output."
    log "ERROR" "No USB status output"
    exit 1
  fi
  # Add USB protocol info
  local usb_protocol="unknown"
  if [[ "$usb_info" =~ "Spd=5000" ]]; then
    usb_protocol="3.0"
  elif [[ "$usb_info" =~ "Spd=480" ]]; then
    usb_protocol="2.0"
  fi
  usb_status=$(echo "$usb_status" | jq -r --arg protocol "$usb_protocol" '.blockdevices[] |= (if .attached and .name=="sdb" then . + {"usb_protocol": $protocol} else . end)')
  log "INFO" "USB status: $usb_status"
  # Add boot drive status for sda
  local sda_boot
  sda_boot=$(check_boot_drive "sda")
  usb_status=$(echo "$usb_status" | jq -r --arg boot "$sda_boot" '.blockdevices[] |= (if .name=="sda" then . + {"is_boot": ($boot == "true")} else . end)')
  log "INFO" "Updated USB status with boot and protocol: $usb_status"
  # Save to JSON files
  for file in "$OUTPUT_JSON" "$REGISTRY_JSON"; do
    if ! echo "$usb_status" >"$file"; then
      feedback "ERROR: Cannot write to $file"
      log "ERROR" "Cannot write to $file"
      exit 1
    fi
    if ! chmod 664 "$file" 2>/dev/null; then
      feedback "WARNING: Cannot set permissions on $file"
      log "WARNING" "Cannot set permissions on $file"
    fi
    if ! chown "$USER:$USER" "$file" 2>/dev/null; then
      feedback "WARNING: Cannot set ownership on $file"
      log "WARNING" "Cannot set ownership on $file"
    fi
  done
  log "INFO" "Saved USB status to $OUTPUT_JSON and $REGISTRY_JSON"
  feedback "USB status:"
  echo "$usb_status" | jq .
}

# Main function
main() {
  log "INFO" "Script started"
  check_sudo
  check_dependencies
  detect_usb_devices
  log "INFO" "Script completed"
}

# Run main
main "$@"

# End of script

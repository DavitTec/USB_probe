#!/bin/bash
# usb_info.sh
# version 0.10
# Detects USB ports, gathers pendrive info, creates USB_Registry.json
# Requires sudo for lsusb, lsblk, blkid, and file operations

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

# Define files
LOG_FILE="$LOG_DIR/usb_script.log"
TEMP_REGISTRY="$LOG_DIR/usb_baseline.json"
LOCAL_REGISTRY="$REGISTRY_DIR/USB_Registry.json"
LSBLK_NONE="$LOG_DIR/lsblk_output_none.json"
LSBLK_TEST="$LOG_DIR/lsblk_output_TEST1.json"

# Create log directory
if [ ! -d "$LOG_DIR" ]; then
  if ! mkdir -p "$LOG_DIR"; then
    echo "ERROR: Cannot create log directory $LOG_DIR"
    exit 1
  fi
  if ! chmod 775 "$LOG_DIR"; then
    echo "ERROR: Cannot set permissions on $LOG_DIR"
    exit 1
  fi
  if ! chown david:david "$LOG_DIR"; then
    echo "ERROR: Cannot set ownership on $LOG_DIR"
    exit 1
  fi
fi

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
if ! chown david:david "$LOG_FILE" 2>/dev/null; then
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
  for cmd in jq lsblk lsusb blkid; do
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

# Prompt user to remove USB pendrives
prompt_remove_usb() {
  feedback "Please remove all USB pendrives and press Enter to continue..."
  log "INFO" "Prompting user to remove USB pendrives"
  read -r
  # Unmount any USB devices
  local mounts
  mounts=$(lsblk -J 2>/dev/null | jq -r '.blockdevices[] | select(.type=="disk") | .children[]?.mountpoint // empty' 2>/dev/null | grep -v null)
  if [[ -n "$mounts" ]]; then
    while IFS= read -r mount; do
      if ! umount "$mount" 2>/dev/null; then
        feedback "WARNING: Failed to unmount $mount"
        log "WARNING" "Failed to unmount $mount"
      else
        feedback "Unmounted $mount"
        log "INFO" "Unmounted $mount"
      fi
    done <<< "$mounts"
  fi
  # Save lsblk output (no pendrives)
  lsblk -J -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,UUID >"$LSBLK_NONE" 2>/dev/null
  log "INFO" "Saved lsblk output (no pendrives) to $LSBLK_NONE"
  log "INFO" "USB removal prompt completed"
}

# Create baseline USB registry
create_baseline_registry() {
  feedback "Creating baseline USB registry..."
  log "INFO" "Creating baseline USB registry"
  local usb_info
  usb_info=$(lsusb -v 2>/dev/null)
  local lsblk_info
  lsblk_info=$(lsblk -J -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,UUID 2>/dev/null)
  local blkid_info
  blkid_info=$(blkid 2>/dev/null)
  local baseline
  baseline=$(jq -n --arg usb "$usb_info" --arg lsblk "$lsblk_info" --arg blkid "$blkid_info" \
    '{usb: $usb, lsblk: $lsblk, blkid: $blkid}' 2>/dev/null)
  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    feedback "ERROR: Failed to create baseline JSON."
    log "ERROR" "Failed to create baseline JSON: usb=$usb_info, lsblk=$lsblk_info, blkid=$blkid_info"
    exit 1
  fi
  if ! echo "$baseline" >"$TEMP_REGISTRY"; then
    feedback "ERROR: Cannot write to $TEMP_REGISTRY"
    log "ERROR" "Cannot write to $TEMP_REGISTRY"
    exit 1
  fi
  log "INFO" "Baseline registry created: $baseline"
}

# Prompt user to reattach USB pendrives
prompt_reattach_usb() {
  feedback "Please reattach USB pendrives and press Enter to continue..."
  log "INFO" "Prompting user to reattach USB pendrives"
  read -r
  # Save lsblk output (with pendrives)
  lsblk -J -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,UUID >"$LSBLK_TEST" 2>/dev/null
  log "INFO" "Saved lsblk output (with pendrives) to $LSBLK_TEST"
}

# Gather pendrive info
gather_pendrive_info() {
  feedback "Gathering pendrive information..."
  log "INFO" "Starting pendrive info collection"
  local lsblk_output
  lsblk_output=$(lsblk -J -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,UUID 2>/dev/null)
  log "INFO" "lsblk output: $lsblk_output"
  if [[ -z "$lsblk_output" ]]; then
    feedback "ERROR: lsblk output is empty."
    log "ERROR" "lsblk output is empty"
    exit 1
  fi
  local pendrives
  pendrives=$(echo "$lsblk_output" | jq '[.blockdevices[] | select(.type=="disk" and .name | test("^sd[a-z]+$")) | {name, size, type, fstype, label, mountpoint, uuid, children: (.children // [] | map(select(.type=="part") | {name, size, type, fstype, label, mountpoint, uuid}))}]' 2>/dev/null)
# shellcheck disable=SC2181  
  if [[ $? -ne 0 ]]; then
    feedback "ERROR: Failed to parse lsblk output with jq."
    log "ERROR" "Failed to parse lsblk output: $lsblk_output"
    exit 1
  fi
  if [[ -z "$pendrives" || "$pendrives" == "[]" ]]; then
    feedback "No pendrives found."
    log "ERROR" "No pendrives detected"
    exit 1
  fi
  local count
  count=$(echo "$pendrives" | jq 'length')
  log "INFO" "Found $count pendrives: $pendrives"
  local usb_info
  usb_info=$(lsusb -v 2>/dev/null)
  log "INFO" "USB info: $usb_info"
  local blkid_info
  blkid_info=$(blkid 2>/dev/null)
  log "INFO" "blkid info: $blkid_info"
  local df_info
  df_info=$(df -h 2>/dev/null)
  log "INFO" "df info: $df_info"
  local pendrive_details
  pendrive_details=$(jq -n --arg lsblk "$pendrives" --arg usb "$usb_info" --arg blkid "$blkid_info" --arg df "$df_info" \
    '{lsblk: ($lsblk | fromjson), usb: $usb, blkid: $blkid, df: $df}' 2>/dev/null)
  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    feedback "ERROR: Failed to create pendrive JSON."
    log "ERROR" "Failed to create pendrive JSON: $pendrive_details"
    exit 1
  fi
  log "INFO" "Pendrive details: $pendrive_details"
  echo "$pendrive_details"
}

# Compare registries
compare_registries() {
  local baseline="$1"
  local current="$2"
  feedback "Comparing USB registries..."
  log "INFO" "Comparing baseline and current registries"
  local diff
  diff=$(jq -n --arg baseline "$baseline" --arg current "$current" \
    '{changes: ($current | fromjson | .lsblk != ($baseline | fromjson | .lsblk))}' 2>/dev/null)
  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    feedback "ERROR: Failed to compare registries."
    log "ERROR" "Failed to compare registries: baseline=$baseline, current=$current"
    exit 1
  fi
  log "INFO" "Registry comparison: $diff"
  echo "$diff"
  # Compare lsblk outputs with meld
  if command -v meld >/dev/null 2>&1; then
    feedback "Opening meld to compare $LSBLK_NONE and $LSBLK_TEST"
    log "INFO" "Opening meld to compare lsblk outputs"
    meld "$LSBLK_NONE" "$LSBLK_TEST" &
  else
    feedback "WARNING: meld not installed, skipping visual diff."
    log "WARNING" "meld not installed"
  fi
}

# Check USB speed
check_usb_speed() {
  local pendrive_info="$1"
  feedback "Checking USB speed..."
  log "INFO" "Checking USB speed for pendrives"
  local usb_info
  usb_info=$(lsusb -v 2>/dev/null | grep -E 'bDeviceProtocol|bMaxPacketSize0' | grep -B1 'bDeviceProtocol.*3')
  if [[ -n "$usb_info" ]]; then
    feedback "High-speed USB (3.0+) detected."
    log "INFO" "High-speed USB detected: $usb_info"
  else
    feedback "WARNING: No high-speed USB (3.0+) detected. Consider moving pendrives to faster ports."
    log "WARNING" "No high-speed USB detected"
  fi
}

# Choose pendrive
choose_pendrive() {
  local pendrive_info="$1"
  feedback "Available pendrives:"
  local names
  names=$(echo "$pendrive_info" | jq -r '.lsblk[].name' 2>/dev/null)
  if [[ -z "$names" ]]; then
    feedback "No valid pendrive names found."
    log "ERROR" "No valid pendrive names found: $pendrive_info"
    exit 1
  fi
  log "INFO" "Available pendrives: $names"
  echo "$names" | tr ' ' '\n'
  log "INFO" "Prompting user to choose pendrive"
  read -r -p "Enter pendrive device name (e.g., sdb): " device_name
  if [[ -z "$device_name" ]]; then
    feedback "ERROR: No device name entered."
    log "ERROR" "No device name entered"
    exit 1
  fi
  log "INFO" "User entered device name: $device_name"
  # Validate device
  if ! echo "$pendrive_info" | jq -e ".lsblk[] | select(.name==\"$device_name\")" >/dev/null 2>&1; then
    feedback "Invalid pendrive device."
    log "ERROR" "Invalid pendrive choice: $device_name"
    exit 1
  fi
  local mount_point
  mount_point=$(echo "$pendrive_info" | jq -r ".lsblk[] | select(.name==\"$device_name\") | .mountpoint // (.children[]?.mountpoint // \"\") | select(. != \"\")" 2>/dev/null | head -n 1)
  if [[ -z "$mount_point" ]]; then
    feedback "WARNING: No mount point found for $device_name. Attempting to mount..."
    log "INFO" "Attempting to mount $device_name"
    mount_point="/media/david/$device_name"
    if ! mkdir -p "$mount_point" || ! mount "/dev/$device_name" "$mount_point" 2>/dev/null; then
      feedback "ERROR: Failed to mount $device_name."
      log "ERROR" "Failed to mount $device_name"
      exit 1
    fi
    log "INFO" "Mounted $device_name at $mount_point"
  fi
  log "INFO" "User chose pendrive: $device_name, mount point: $mount_point"
  echo "$device_name $mount_point"
}

# Create USB_Registry.json
create_usb_registry() {
  local pendrive_info="$1"
  local device_name="$2"
  local mount_point="$3"
  local json_file="$mount_point/USB_Registry.json"
  local local_json="$LOCAL_REGISTRY"
  feedback "Creating USB_Registry.json..."
  log "INFO" "Creating JSON at $json_file and $local_json"
  if [[ -z "$mount_point" || ! -d "$mount_point" ]]; then
    feedback "ERROR: Pendrive not mounted."
    log "ERROR" "Pendrive not mounted: $device_name"
    exit 1
  fi
  if ! echo "$pendrive_info" >"$json_file" 2>/dev/null; then
    feedback "Failed to write JSON to pendrive."
    log "ERROR" "Write failed for $json_file"
    exit 1
  fi
  if ! chmod u+rw "$json_file" 2>/dev/null; then
    log "WARNING" "Cannot set permissions on $json_file"
  fi
  if ! echo "$pendrive_info" >"$local_json" 2>/dev/null; then
    feedback "Failed to write local JSON."
    log "ERROR" "Write failed for $local_json"
    exit 1
  fi
  if ! chmod u+rw "$local_json" 2>/dev/null; then
    log "WARNING" "Cannot set permissions on $local_json"
  fi
  feedback "USB_Registry.json created successfully on pendrive and locally."
  log "INFO" "JSON created and permissions set"
}

# Main function
main() {
  log "INFO" "Script started"

  # Check sudo
  check_sudo

  # Check dependencies
  check_dependencies

  # Prompt to remove USBs
  prompt_remove_usb

  # Create baseline registry
  create_baseline_registry

  # Prompt to reattach USBs
  prompt_reattach_usb

  # Gather pendrive info
  pendrive_info=$(gather_pendrive_info)
  log "INFO" "Pendrive info returned: $pendrive_info"

  # Compare registries
  baseline=$(cat "$TEMP_REGISTRY" 2>/dev/null)
  diff=$(compare_registries "$baseline" "$pendrive_info")
  log "INFO" "Registry diff: $diff"

  # Check USB speed
  check_usb_speed "$pendrive_info"

  # Choose pendrive
  read -r device_name mount_point <<< "$(choose_pendrive "$pendrive_info")"
  log "INFO" "Selected device: $device_name, mount point: $mount_point"

  # Create JSON
  create_usb_registry "$pendrive_info" "$device_name" "$mount_point"

  log "INFO" "Script completed successfully"
}

# Run main
main "$@"

# end of script

#!/bin/bash
# logging.sh
# Version: 0.2.1
# Purpose: Centralized logging functions for setup scripts

# read .env file if it exists
if [ -f ".env" ]; then
  # shellcheck disable=SC1091
  source .env
else
  echo "No .env file found. Using default paths."
  exit 1
fi

# Logging Function
log() {
  local timestamp script_name log_file
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  script_name=$(basename "${BASH_SOURCE[1]}" .sh)
  log_file="${LOG_DIR}/${script_name}_$(date '+%Y%m%d').log"
  echo "[$timestamp] $1" >&2
  mkdir -p "$LOG_DIR"
  echo "[$timestamp] $1" >>"$log_file"
}

# end of script

#!/bin/bash
# main.sh
# version 0.1
# Driver script for USB_probe project: develop, test, release, commit, version

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

# Commands
case "$1" in
  lint)
    echo "Running lint..."
    shellcheck "$SCRIPT_DIR/usb_info.sh"
    prettier --check "$SCRIPT_DIR/../."
    ;;
  format)
    echo "Formatting code..."
    prettier --write "$SCRIPT_DIR/../."
    ;;
  test)
    echo "Running tests..."
    sudo bash "$SCRIPT_DIR/../tests/test_usb_info.sh"
    ;;
  run)
    echo "Running usb_info.sh..."
    sudo bash "$SCRIPT_DIR/usb_info.sh"
    cat "$LOG_DIR/usb_script.log"
    ;;
  commit)
    echo "Committing changes..."
    git add .
    npx cz
    ;;
  release)
    echo "Creating release..."
    git tag "v$(jq -r '.version' package.json)"
    git push origin main
    git push origin --tags
    ;;
  *)
    echo "Usage: $0 {lint|format|test|run|commit|release}"
    exit 1
    ;;
esac


# end of main.sh
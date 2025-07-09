# USB_probe Project Summary

## Overview

The `USB_probe` project, hosted at `https://github.com/DavitTec/USB_probe`, aims to develop a Bash script to detect and report the state of USB storage devices (`sd[a-f]`) on Linux systems (Linux Mint 21.3, Ubuntu 22.04-based). The script queries device attachment status (`true`/`false`), identifies boot drives, and collects metadata (e.g., size, filesystem, mount points, USB protocol). The project is located at `/opt/davit/development/usb_probe` and uses a monorepo structure with scripts, tests, and logs.

## Goals

- **Primary Objective**: Accurately determine the current state of `sd[a-f]` devices without user interaction.
- **Boot Drive Detection**: Identify if `/dev/sda` is a boot drive or removable storage.
- **USB Protocol**: Report USB protocol (e.g., USB 2.0/3.0) for attached devices using `usb-devices`.
- **Output**: Save results to `usb_registry.json` in `logs/` and `.davit/` directories.
- **Flexibility**: Support various scenarios (formatted/unformatted drives, multiple computers).
- **Simplicity**: Avoid complex user prompts or loops expecting hardware changes.

## Project Structure

- **Base Directory**: `/opt/davit/development/usb_probe`
- **Key Files**:
  - `scripts/main.sh`: Entry point to run `usb_info.sh` or test scripts.
  - `scripts/usb_info.sh`: Original script to detect USB devices and create `USB_Registry.json` (currently problematic).
  - `tests/test_usb_simple.sh`: Simplified test script to detect `sd[a-f]` attachment status.
  - `.env`: Environment variables (`BASE_DIR`, `SCRIPT_DIR`, `LOG_DIR`, `REGISTRY_DIR`).
  - `logs/`: Stores logs (`test_usb_simple.log`, `usb_registry.json`) and previous outputs (`lsblk_output_none.json`, `lsblk_output_TEST1.json`).
  - `.davit/`: Stores `usb_registry.json`.
- **Dependencies**: `jq`, `lsblk`, `usb-devices` (from `usbutils`).

## Progress and Challenges

### Initial Attempts (`usb_info.sh`)

- **Version**: 0.12
- **Issues**:
  - `jq` parsing errors in `gather_pendrive_info` due to missing `RM` field in `lsblk` output.
  - Relied on user prompts to remove/attach pendrives, leading to test failures if instructions were ignored.
  - Failed to create `USB_Registry.json` due to empty `pendrives` array.
  - Complex logic for comparing `lsblk` outputs and checking USB speed.
- **Logs**:
  - `usb_script.log` (2025-07-08): Showed `ERROR: Failed to parse lsblk output with jq: 0`, `No valid pendrive names found`, and `Pendrive not mounted: Available`.
  - `lsblk_output_TEST1.json`: Confirmed `/dev/sdb` (14.8G, `058f:6387`, USB 2.0) with `/dev/sdb1` (4G, vfat, `/media/david/BOOT`).
  - `usb-devices.4.txt`: Verified pendrive presence on Bus 01 (480Mbps).

### Simplified Approach (`test_usb_simple.sh`)

- **Version**: 0.4 (updated to 0.5 in this response)
- **Improvements**:
  - Adopted a reliable `jq` command to detect `sd[a-f]` attachment status:

    ```bash
    lsblk -J -o NAME | jq -r '. as $input | { "device": "test", "slots": 4, "blockdevices": ([.blockdevices[] | select(.name | startswith("sd")) | { "name": .name, "attached": true }] + (["sda","sdb","sdc","sdd","sde","sdf"] | map(select(. as $name | [$input.blockdevices[].name] | index($name) | not)) | map({ "name": ., "attached": false })) | sort_by(.name)) }'
    ```

  - Used `STORAGE_DEVICES` array for flexibility.
  - Added retry logic for user prompts (removed in v0.5).

- **Issues**:
  - Version 0.4 failed if users didn’t remove pendrives, causing `test_no_usb` to fail.
  - JQ variable integration was correct but lacked boot drive and USB protocol checks.
  - No handling for corrupted/unformatted drives.

### Current State (Version 0.5)

- **Script**: `test_usb_simple.sh` v0.5
- **Features**:
  - Queries current state of `sd[a-f]` without user prompts.
  - Checks if `/dev/sda` is a boot drive using mount points.
  - Includes metadata (`SIZE`, `FSTYPE`, `LABEL`, `MOUNTPOINT`, `UUID`, `children`).
  - Adds `usb_protocol` (e.g., "2.0", "3.0") for `/dev/sdb` based on `usb-devices`.
  - Saves output to `logs/usb_registry.json` and `.davit/usb_registry.json`.
- **Remaining Tasks**:
  - Test with unformatted/corrupted drives.
  - Support multiple computers with varying USB ports.
  - Refine USB protocol detection for USB 3.2 or other vendors.

## Next Steps

- **Testing**: Run `test_usb_simple.sh` v0.5 with formatted/unformatted drives and different computers.
- **Enhancements**:
  - Add handling for corrupted drives (e.g., check `blkid` for missing filesystems).
  - Correlate `lsblk` devices with `usb-devices` for all USB devices, not just `058f:6387`.
  - Allow filtering out boot drives in `usb_registry.json`.
- **Integration**: Update `usb_info.sh` to use simplified detection logic from `test_usb_simple.sh`.
- **Documentation**: Maintain a `README.md` with usage instructions and test scenarios.

## Recommendations

- Run tests with and without pendrives to verify state detection.
- Share logs and `usb_registry.json` to confirm output format.
- Specify additional metadata (e.g., serial number, vendor) for inclusion in `usb_registry.json`.
- Test on a system booting from a USB drive to validate `/dev/sda` handling.

# USB_probe

A standalone Bash utility for probing USB ports and pendrives, creating a `USB_Registry.json` with device information.

> [!WARNING]
>
> This project in still in development and a alpha phase release, **Version 0.1**
> time tió review

## Features

- Detects USB ports and buses (`lsusb`).
- Gathers pendrive info (name, size, partitions, filesystem, mount points) using `lsblk`, `blkid`, `df`.
- Creates baseline and current USB registries, compares for changes.
- Checks USB speed (2.0 vs. 3.0+) and prompts for optimal port placement.
- Writes `USB_Registry.json` to pendrive and locally.
- Robust logging and error handling.

## Requirements

- Linux (Ubuntu 22.04+ or derivatives like Linux Mint 21.3)
- Tools: `jq`, `usbutils` (`lsusb`), `util-linux` (`lsblk`, `blkid`), `coreutils` (`df`), usb-devices
- Sudo privileges for USB and file operations

## Installation

```bash
git clone https://github.com/DavitTec/USB_probe.git
cd USB_probe
pnpm install
sudo apt-get install jq usbutils
```

## Usage

```bash
sudo ./scripts/usb_info.sh
```

- Follow prompts to remove/reattach USB pendrives.
- Check logs: `cat logs/usb_script.log`

## Development

### Key Points and Goals

1. **Current State Detection**: Determine the attachment status (true/false) of sd[a-f] devices
   using lsblk and your jq command, without requiring user interaction.
2. **Handle /dev/sda**: Identify if /dev/sda is a boot drive (e.g., system disk) or removable storage,
   and decide whether to include it in USB device checks.
3. **No User Action**: Avoid prompting users to add/remove devices during state detection. Use system
   commands (umount, lsblk, usb-devices) to query the current state.
4. **Ignore Unknowns**: TODO: Only report known devices (sd[a-f]) and exclude irrelevant or unknown devices.
5. **USB Protocol Version**: Plan to check USB protocol (e.g., USB 2.0/3.0) using usb-devices
   output (e.g., 058f:6387 on Bus 01, 480Mbps).
6. **Flexible Testing**: Ensure the script works across scenarios (formatted/unformatted drives,
   corrupted drives, different computers).
7. **Output**: Store results in a usb_registry.json file for querying, including device state and
   metadata (e.g., mount points, USB speed).
8. **Script Structure**: Maintain a clear header (#!/bin/bash, version, description) and footer (# End of script).

### Running this application

The UI and GUI goals for the utility is be multi-functional. At this stage the

```bash
pnpm main lint    # Run shellcheck and prettier
pnpm main format  # Format code
pnpm main test1    # Run test1
pnpm main test2    # Run test2
pnpm main run     # Run usb_info.sh
pnpm main commit  # Commit with conventional changelog
pnpm main release # Tag and push release  or
# note "main" is optional
pnpm release # Tag and push release  or
pnpm main # provides help or usage
```

### Testing

#### Test the Script

1. Run with pendrive attached:
   - ```bash
     cd ./usb_probe
     sudo ./scripts/main.sh test1 #or pnpm main test1
     ```

2. Inspect Outputs
   - ```bash
     cat ./usb_probe/logs/test_usb_simple.log
     cat ./usb_probe/logs/usb_registry.json
     cat ./usb_probe/.davit/usb_registry.json
     ```

3.

### Summary

The new `test_usb_simple.sh v0.5` eliminates user prompts, accurately detects `sd[a-f]` state,
checks if `/dev/sda` is a boot drive, and includes USB protocol info. It saves results to usb_registry.json
for querying. The Markdown summary documents the project’s progress and challenges. Run the tests and share
results to confirm functionality, then we can address additional scenarios!

## Project Documents

- **[usb probe project summary](docs/USB_probe_project_summary.md)**

## TODO

1. Provide help menu in main.sh

## License

MIT

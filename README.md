# USB_probe

A standalone Bash utility for probing USB ports and pendrives, creating a `USB_Registry.json` with device information.

## Features

- Detects USB ports and buses (`lsusb`).
- Gathers pendrive info (name, size, partitions, filesystem, mount points) using `lsblk`, `blkid`, `df`.
- Creates baseline and current USB registries, compares for changes.
- Checks USB speed (2.0 vs. 3.0+) and prompts for optimal port placement.
- Writes `USB_Registry.json` to pendrive and locally.
- Robust logging and error handling.

## Requirements

- Linux (Ubuntu 22.04+ or derivatives like Linux Mint 21.3)
- Tools: `jq`, `usbutils` (`lsusb`), `util-linux` (`lsblk`, `blkid`), `coreutils` (`df`)
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

```bash
./scripts/main.sh lint    # Run shellcheck and prettier
./scripts/main.sh format  # Format code
./scripts/main.sh test    # Run tests
./scripts/main.sh run     # Run usb_info.sh
./scripts/main.sh commit  # Commit with conventional changelog
./scripts/main.sh release # Tag and push release
```

## License

MIT

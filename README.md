# Proxmox Update Log Viewer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Proxmox%20VE-orange.svg)](https://www.proxmox.com/)

A comprehensive bash script for viewing Proxmox update log entries with flexible time filtering, colored output, and line numbering. Perfect for monitoring system updates on Proxmox VMs and Container Templates (CTs).

## Features

- **🕒 Flexible Time Filtering**: View logs from specific time ranges (hours, days, minutes, or custom timestamps)
- **🎨 Enhanced Color Coding**: Intelligent color highlighting for different log types and operations
- **📝 Line Numbering**: Sequential numbering of filtered entries for easy reference
- **🐳 Docker Compose Support**: Special highlighting for container operations (pulling, running, cleanup)
- **🌍 Multi-Timezone Support**: Handles both 12-hour/24-hour formats across different timezones
- **📋 Package Operation Highlighting**: Clear visual indicators for system updates and package changes
- **⚙️ Multiple Time Options**: Hours, days, minutes, or specific timestamps
- **🛡️ Robust Error Handling**: Comprehensive validation and user-friendly error messages
- **🔇 Quiet Mode**: Minimal output perfect for scripting and automation
- **📊 Professional Output**: Clean, organized display with headers and summaries

## Table of Contents

- [Features](#features)
- [Installation](#installation)
  - [Quick Install from GitHub](#quick-install-from-github)
  - [Manual Installation Options](#manual-installation-options)
- [Usage](#usage)
- [Supported Log Formats](#supported-log-formats)
- [Color Coding](#color-coding)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Compatibility](#compatibility)

## Requirements

- **Operating System**: Linux (Proxmox VE, VMs, or CTs)
- **Shell**: Bash 4.0 or later
- **Dependencies**: Standard Linux utilities (`date`, `grep`, `sed`)
- **Permissions**: Read access to `/var/log/update-logs/update.log`

## Installation

### Quick Install from GitHub

#### Method 1: Clone Repository
```bash
# Clone the repository
git clone https://github.com/vehask/view-update-log.git
cd view-update-log

# Run automated installer
sudo ./install.sh
```

#### Method 2: Direct Download and Install
```bash
# Download and install in one command
curl -sSL https://raw.githubusercontent.com/vehask/view-update-log/main/view-update-log.sh -o view-update-log.sh && \
sudo cp view-update-log.sh /usr/local/bin/ && \
sudo chmod +x /usr/local/bin/view-update-log.sh && \
echo "Installation complete! Run './view-update-log.sh --help' to get started."
```

#### Method 3: Download and Run Locally
```bash
# Download script
curl -sSL https://raw.githubusercontent.com/vehask/view-update-log/main/view-update-log.sh -o view-update-log.sh

# Make executable
chmod +x view-update-log.sh

# Run locally
./view-update-log.sh --help
```

### Manual Installation Options

#### Option 1: System-wide Installation (Recommended)

```bash
# Copy script to system binary directory
sudo cp view-update-log.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/view-update-log.sh

#### Option 2: Local Installation

```bash
# Make script executable
chmod +x view-update-log.sh

# Run from current directory
./view-update-log.sh
```

#### Option 3: Custom Directory

```bash
# Create scripts directory
mkdir -p /path/to/scripts
sudo cp view-update-log.sh /path/to/scripts
sudo chmod +x /path/to/view-update-log.sh

# Add to PATH (optional)
echo 'export PATH="/path/to/scripts:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Option 4: Using the Automated Installer

```bash
# Run the included installer script
sudo ./install.sh

# The installer will:
# - Copy the script to /usr/local/bin/
# - Set proper permissions
# - Create a convenient symlink
# - Validate the installation
```

## Usage

### Basic Usage

```bash
# View last 24 hours (default)
./view-update-log.sh

# View with help
./view-update-log.sh --help
```

### Time Range Options

```bash
# View last 12 hours
./view-update-log.sh --hours 12

# View last 3 days
./view-update-log.sh --days 3

# View last 30 minutes
./view-update-log.sh --minutes 30

# View from specific date/time
./view-update-log.sh --since "2025-01-20 10:00:00"

# View until specific date/time
./view-update-log.sh --until "2025-01-23 12:00:00"

# View specific time range
./view-update-log.sh --since "2025-01-20" --until "2025-01-22"
```

### Display Options

```bash
# Disable colors (for redirecting to files)
./view-update-log.sh --hours 6 --no-color

# Disable line numbers
./view-update-log.sh --no-line-numbers

# Quiet mode (no header/summary)
./view-update-log.sh --quiet

# Combine options
./view-update-log.sh --days 1 --no-color --quiet > recent-updates.txt
```

### Advanced Usage

```bash
# Pipe to less for pagination (preserves colors)
./view-update-log.sh --days 7 | less -R

# Save to file without colors
./view-update-log.sh --hours 24 --no-color > daily-updates.log

# Search for specific patterns
./view-update-log.sh --days 3 | grep -i "error"

# Count entries by type
./view-update-log.sh --days 1 --quiet | grep -c "ERROR"
```

## Supported Log Formats

The script automatically detects and parses various timestamp formats from Proxmox update logs:

### Time Formats
- **12-hour format**: `05:00:01 AM`, `11:30:45 PM`
- **24-hour format**: `17:00:01`, `23:30:45`

### Timezone Support
- **Common abbreviations**: `CEST`, `CET`, `UTC`, `GMT`, `EST`, `PST`, etc.
- **Numeric offsets**: `+0200`, `-0500`, `+00:00`
- **Extended zones**: `UTC+2`, `GMT-5`

### Header Formats
- **Equal signs**: `==== Thu Jul 17 05:00:01 AM CEST 2025 ====`
- **Hash symbols**: `########## Wed Jul 23 17:30:15 UTC 2025 ##########`

### Examples of Supported Headers
```
==== Thu Jul 17 05:00:01 AM CEST 2025 ====     (12-hour with CEST)
==== Thu Jul 17 17:00:01 UTC 2025 ====         (24-hour with UTC)
########## Wed Jul 23 14:30:15 CET 2025 ##########  (24-hour with CET)
########## Wed Jul 23 09:15:30 PM EST 2025 ########## (12-hour with EST)
```

## Command-Line Timestamp Formats

The script accepts various timestamp formats for `--since` and `--until` options:

- **Full timestamp**: `"2025-01-23 14:30:00"`
- **Date only**: `"2025-01-23"` (assumes 00:00:00)
- **Time only**: `"14:30:00"` (assumes today's date)
- **Relative**: `"yesterday"`, `"last week"`, etc.

## Log File Location

The script looks for the update log at:
```
/var/log/update-logs/update.log
```

## Color Coding

The script uses intelligent color coding to make log analysis easier:

### System Messages
- **🟢 Green**: Line numbers and completion indicators
- **🔵 Blue**: INFO level messages
- **🟡 Yellow**: WARNING level messages and package operations
- **🔴 Red**: ERROR/CRITICAL messages and deletion operations
- **⚪ Gray**: DEBUG messages
- **⚪ White**: General log entries

### Special Highlighting

#### 🟠 Orange - Timestamp Headers
- `########## Fri Jul 25 05:00:01 AM CEST 2025 ##########`
- `==== Thu Jul 17 17:00:01 UTC 2025 ====`

#### 🟡 Yellow - Package Operations & Docker Pulling
- `5 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.`
- `The following NEW packages will be installed:`
- `The following packages will be upgraded:`
- `convertx Pulling`, `watchtower Pulling`
- `Container jackett Starting`

#### 🟢 Green - Completed Operations
- `Download complete`, `Pull complete`
- `watchtower Pulled`, `bazarr Pulled`
- `Container bazarr Running`, `Container jackett Started`
- `Total reclaimed space: 514.6MB`
- `########## Update Complete ##########`

#### 🔴 Red - Cleanup & Errors
- `deleted: sha256:...`
- `untagged: ghcr.io/...`
- Critical error messages

## Exit Codes

- `0`: Success
- `1`: General error
- `2`: Invalid arguments
- `3`: Log file not found or not readable

## Examples

### Example 1: Daily Check
```bash
# Quick daily update check
./view-update-log.sh --hours 24
```

### Example 2: Investigation Mode
```bash
# Detailed investigation of recent issues
./view-update-log.sh --days 3 | less -R
```

### Example 3: Automated Reporting
```bash
# Generate clean report for email/documentation
./view-update-log.sh --days 7 --no-color --quiet > weekly-updates.txt
```

### Example 4: Error Analysis
```bash
# Focus on errors from last week
./view-update-log.sh --days 7 | grep -E "(ERROR|CRITICAL|FATAL)"
```

## Troubleshooting

### Permission Issues
```bash
# If you get permission denied
sudo chmod +x view-update-log.sh

# If log file is not readable
sudo chmod +r /var/log/update-logs/update.log
```

### Log File Not Found
```bash
# Check if log directory exists
ls -la /var/log/update-logs/

# Create log directory if needed (as root)
sudo mkdir -p /var/log/update-logs
```

### Timestamp Parsing Issues
- Ensure your log entries have recognizable timestamp formats
- The script supports common formats but may need adjustment for custom logs

## Compatibility

- **Proxmox VE**: All versions
- **Container Templates**: Most Linux distributions
- **Virtual Machines**: Any Linux VM with bash
- **Dependencies**: Standard bash utilities (date, grep, etc.)

## Customization

You can modify the script to:
- Change color schemes
- Add new timestamp formats
- Adjust log file location
- Add custom filtering options

## Screenshots

*Coming soon - Screenshots showing the colorized output and different log views*

## Contributing

We welcome contributions! Please feel free to submit issues, feature requests, or pull requests.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Reporting Issues

When reporting issues, please include:
- Your Proxmox version
- Operating system details
- Sample log entries (if relevant)
- Steps to reproduce the issue

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues or feature requests:

1. **Check the [Issues](https://github.com/YOUR_USERNAME/proxmox-update-log-viewer/issues)** page
2. **Review [Troubleshooting](#troubleshooting)** section
3. **Verify requirements**: Log file permissions, timestamp compatibility, bash 4.0+
4. **Create a new issue** with detailed information

## Changelog

### v1.2 (Latest)
- ✨ **Docker Compose Support**: Added specialized color highlighting for container operations
- 🎨 **Enhanced Color Scheme**: Orange headers, yellow package operations, green completions
- 🌍 **Improved Timezone Support**: Better handling of Day-Month vs Month-Day date formats
- 📦 **Package Operation Highlighting**: Clear visual indicators for system updates
- 🔧 **Bug Fixes**: Resolved 24-hour format parsing issues

### v1.1
- 🕒 **Multi-Format Support**: Added support for both 12-hour and 24-hour time formats
- 🌐 **Enhanced Timezone Handling**: Support for CEST, UTC, GMT, EST, PST, and numeric offsets
- 🔍 **Sectioned Log Parsing**: Improved timestamp header detection and processing
- ⚡ **Performance Improvements**: Optimized regex patterns and parsing logic

### v1.0
- 🚀 **Initial Release**: Core functionality with flexible time filtering
- 🎨 **Colored Output**: Basic color coding for log levels
- 📝 **Line Numbering**: Sequential numbering of filtered entries
- ⚙️ **Command-Line Options**: Comprehensive argument parsing and validation
- 🛡️ **Error Handling**: Robust validation and user-friendly messages

---

**Made with ❤️ for the Proxmox community**


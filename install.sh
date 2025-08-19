#!/bin/bash

# ╭─────────────────────────────────────────────────────────────╮
# │            Proxmox Update Log Viewer Installer             │
# │                                                             │
# │  This script installs the view-update-log.sh script        │
# │  system-wide for easy access on Proxmox VMs and CTs        │
# ╰─────────────────────────────────────────────────────────────╯

set -e

# Configuration
SCRIPT_NAME="view-update-log.sh"
INSTALL_DIR="/usr/local/bin"
SYMLINK_NAME="view-update-log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Print colored output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Print status messages
print_status() {
    print_color "$BLUE" "[INFO] $1"
}

print_success() {
    print_color "$GREEN" "[SUCCESS] $1"
}

print_error() {
    print_color "$RED" "[ERROR] $1" >&2
}

print_warning() {
    print_color "$YELLOW" "[WARNING] $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Check if script exists
check_script_exists() {
    if [[ ! -f "$SCRIPT_NAME" ]]; then
        print_error "Script file '$SCRIPT_NAME' not found in current directory"
        print_error "Please run this installer from the directory containing $SCRIPT_NAME"
        exit 1
    fi
}

# Install script
install_script() {
    print_status "Installing $SCRIPT_NAME to $INSTALL_DIR..."
    
    # Copy script
    cp "$SCRIPT_NAME" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    
    # Create symlink
    if [[ -L "$INSTALL_DIR/$SYMLINK_NAME" ]]; then
        print_warning "Symlink $INSTALL_DIR/$SYMLINK_NAME already exists, removing..."
        rm "$INSTALL_DIR/$SYMLINK_NAME"
    fi
    
    ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SYMLINK_NAME"
    
    print_success "Script installed successfully!"
}

# Create log directory if it doesn't exist
create_log_directory() {
    local log_dir="/var/log/update-logs"
    
    if [[ ! -d "$log_dir" ]]; then
        print_status "Creating log directory: $log_dir"
        mkdir -p "$log_dir"
        chmod 755 "$log_dir"
        print_success "Log directory created"
    else
        print_status "Log directory already exists: $log_dir"
    fi
}

# Test installation
test_installation() {
    print_status "Testing installation..."
    
    if command -v "$SYMLINK_NAME" &> /dev/null; then
        print_success "Command '$SYMLINK_NAME' is available in PATH"
        
        # Test script execution
        if "$SYMLINK_NAME" --help &> /dev/null; then
            print_success "Script executes correctly"
        else
            print_warning "Script installed but may have execution issues"
        fi
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Display usage information
show_usage() {
    print_color "$CYAN" "${BOLD}Proxmox Update Log Viewer Installer${NC}"
    echo
    print_color "$CYAN" "This installer will:"
    echo "  • Copy view-update-log.sh to $INSTALL_DIR"
    echo "  • Make it executable"
    echo "  • Create a symlink for easy access"
    echo "  • Create the log directory if needed"
    echo "  • Test the installation"
    echo
    print_color "$YELLOW" "Requirements:"
    echo "  • Root privileges (sudo)"
    echo "  • view-update-log.sh in current directory"
    echo
    print_color "$GREEN" "Usage:"
    echo "  sudo ./install.sh [--uninstall]"
    echo
}

# Uninstall script
uninstall_script() {
    print_status "Uninstalling Proxmox Update Log Viewer..."
    
    # Remove script
    if [[ -f "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
        rm "$INSTALL_DIR/$SCRIPT_NAME"
        print_success "Removed $INSTALL_DIR/$SCRIPT_NAME"
    fi
    
    # Remove symlink
    if [[ -L "$INSTALL_DIR/$SYMLINK_NAME" ]]; then
        rm "$INSTALL_DIR/$SYMLINK_NAME"
        print_success "Removed $INSTALL_DIR/$SYMLINK_NAME"
    fi
    
    print_success "Uninstallation completed"
}

# Main installation process
main() {
    # Parse arguments
    case "${1:-}" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --uninstall)
            if ! check_root; then
                print_error "Root privileges required for uninstallation"
                print_error "Please run: sudo $0 --uninstall"
                exit 1
            fi
            uninstall_script
            exit 0
            ;;
        "")
            # Continue with installation
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    # Show header
    print_color "$CYAN" "╭─────────────────────────────────────────────────────────────╮"
    print_color "$CYAN" "│${BOLD}            Proxmox Update Log Viewer Installer             ${NC}${CYAN}│"
    print_color "$CYAN" "╰─────────────────────────────────────────────────────────────╯"
    echo
    
    # Check prerequisites
    if ! check_root; then
        print_error "Root privileges required for installation"
        print_error "Please run: sudo $0"
        exit 1
    fi
    
    check_script_exists
    
    # Perform installation
    install_script
    create_log_directory
    test_installation
    
    # Show completion message
    echo
    print_color "$GREEN" "╭─────────────────────────────────────────────────────────────╮"
    print_color "$GREEN" "│${BOLD}                    Installation Complete!                  ${NC}${GREEN}│"
    print_color "$GREEN" "╰─────────────────────────────────────────────────────────────╯"
    echo
    print_success "You can now use the script with these commands:"
    echo "  • $SYMLINK_NAME --help"
    echo "  • $SYMLINK_NAME --hours 12"
    echo "  • $SYMLINK_NAME --days 3"
    echo "  • view-update-log.sh (full name)"
    echo
    print_color "$CYAN" "Example: $SYMLINK_NAME --hours 6 --no-color > recent-updates.txt"
}

# Execute main function
main "$@"
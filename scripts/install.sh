#!/bin/bash

# Lumix Build Tool Installation Script v1.0.0
# Installs the Lumix build system for Luma projects

set -e

VERSION="v1.6.0"
INSTALL_DIR="/usr/local"
BIN_DIR="$INSTALL_DIR/bin"

echo "======================================"
echo "  Lumix Build Tool Installer $VERSION"
echo "======================================"
echo ""

# Check if running as root for system-wide install
if [ "$EUID" -ne 0 ]; then 
    echo "Note: Not running as root. Will attempt user-local installation."
    echo "For system-wide installation, run with sudo."
    echo ""
    
    INSTALL_DIR="$HOME/.local"
    BIN_DIR="$INSTALL_DIR/bin"
    USER_INSTALL=true
fi

# Create directories
echo "Creating installation directories..."
mkdir -p "$BIN_DIR"

# Copy binary
echo "Installing Lumix to $BIN_DIR..."
if [ -f "./lumix" ]; then
    cp ./lumix "$BIN_DIR/"
    chmod +x "$BIN_DIR/lumix"
elif [ -f "./bin/lumix" ]; then
    cp ./bin/lumix "$BIN_DIR/"
    chmod +x "$BIN_DIR/lumix"
else
    echo "Error: Could not find lumix binary!"
    echo "Please ensure 'lumix' is in the current directory or bin/ subdirectory."
    echo ""
    echo "Build Lumix first with:"
    echo "  luma src/lumix.lx -name lumix -l std/io.lx std/sys.lx std/vector.lx std/string.lx std/memory.lx --no-sanitize"
    exit 1
fi

echo ""
echo "Installation complete!"
echo ""
echo "Installed to:"
echo "  Binary: $BIN_DIR/lumix"
echo ""

# Check if bin directory is in PATH
if [ "$USER_INSTALL" = true ]; then
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo "IMPORTANT: Add the following to your ~/.bashrc or ~/.zshrc:"
        echo ""
        echo "  export PATH=\"\$PATH:$BIN_DIR\""
        echo ""
        echo "Then reload your shell with: source ~/.bashrc"
        echo ""
    fi
fi

echo "Usage:"
echo "  cd /path/to/your/luma/project"
echo "  lumix"
echo ""
echo "Commands:"
echo "  build - Build your Luma project"
echo "  clean - Remove build artifacts"
echo "  deps  - Show dependency tree"
echo ""
echo "For more information, see DOCS.md"
echo ""

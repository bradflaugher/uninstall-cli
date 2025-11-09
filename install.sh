#!/bin/bash

# The URL of the uninstall.sh script
SCRIPT_URL="https://raw.githubusercontent.com/bradflaugher/uninstall-cli/main/uninstall.sh"

# The directory to install the script to
INSTALL_DIR="/usr/local/bin"

# The name of the final command
COMMAND_NAME="uninstall"

# Create install directory if it doesn't exist
sudo mkdir -p "$INSTALL_DIR"

# The destination path for the script
DEST_PATH="$INSTALL_DIR/$COMMAND_NAME"

# Download the script
echo "Downloading uninstall script..."
sudo curl -fsSL "$SCRIPT_URL" -o "$DEST_PATH"

# Make the script executable
sudo chmod +x "$DEST_PATH"

echo "Installation complete. You can now use the 'uninstall' command."

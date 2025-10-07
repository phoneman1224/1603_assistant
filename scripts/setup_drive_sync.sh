#!/bin/bash
set -e

echo "Installing required packages..."

# Check for and install required packages
if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    sudo apt-get update
    sudo apt-get install -y \
        git \
        python3 \
        python3-pip \
        rclone \
        jq
elif command -v dnf &> /dev/null; then
    # Fedora/RHEL
    sudo dnf install -y \
        git \
        python3 \
        python3-pip \
        rclone \
        jq
elif command -v pacman &> /dev/null; then
    # Arch Linux
    sudo pacman -Sy \
        git \
        python3 \
        python3-pip \
        rclone \
        jq
fi

# Install required Python packages
pip3 install --user google-api-python-client oauth2client PyDrive2

# Create config directory
mkdir -p ~/.config/1603_assistant

echo "Setting up rclone for Google Drive..."
echo "Please follow the prompts to configure rclone with your Google Drive account."
rclone config

echo "Setup complete! Now you can use sync_to_git.sh to sync files."
#!/bin/bash
set -e

# Configuration
CONFIG_DIR="$HOME/.config/1603_assistant"
TEMP_DIR="/tmp/1603_assistant_sync"
REPO_URL="https://github.com/phoneman1224/1603_assistant.git"
BRANCH="upload-platform-files"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_requirements() {
    for cmd in git rclone jq; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is required but not installed. Please run setup_drive_sync.sh first."
            exit 1
        fi
    done
}

# Sync files from Google Drive
sync_from_drive() {
    print_status "Syncing files from Google Drive..."
    mkdir -p "$TEMP_DIR"
    
    # Sync from Google Drive using rclone
    rclone sync gdrive:/1603_assistant "$TEMP_DIR" --progress
    
    print_success "Files synced from Google Drive"
}

# Organize files into the correct structure
organize_files() {
    print_status "Organizing files..."
    
    # Create platform directories if they don't exist
    mkdir -p "$TEMP_DIR/1603_SM/"{commands,docs,schemas}
    mkdir -p "$TEMP_DIR/16034_SMX/"{commands,docs,schemas}
    
    # Move files to appropriate directories based on patterns
    find "$TEMP_DIR" -type f -name "*command*.json" -exec mv {} "$TEMP_DIR/1603_SM/commands/" \;
    find "$TEMP_DIR" -type f -name "*schema*.json" -exec mv {} "$TEMP_DIR/1603_SM/schemas/" \;
    find "$TEMP_DIR" -type f -name "*.md" -o -name "*.pdf" -exec mv {} "$TEMP_DIR/1603_SM/docs/" \;
    
    print_success "Files organized"
}

# Push to Git repository
push_to_git() {
    print_status "Pushing to Git repository..."
    
    # Clone repository if it doesn't exist
    if [ ! -d "$TEMP_DIR/repo" ]; then
        git clone "$REPO_URL" "$TEMP_DIR/repo"
    fi
    
    cd "$TEMP_DIR/repo"
    
    # Ensure we're on the correct branch
    git fetch origin
    git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
    git pull origin "$BRANCH" || true
    
    # Copy organized files
    cp -r "$TEMP_DIR/1603_SM" "$TEMP_DIR/repo/data/platforms/"
    cp -r "$TEMP_DIR/16034_SMX" "$TEMP_DIR/repo/data/platforms/"
    
    # Commit and push changes
    git add .
    git commit -m "feat: Update platform files from Google Drive sync" || true
    git push origin "$BRANCH"
    
    print_success "Changes pushed to $BRANCH branch"
}

# Cleanup temporary files
cleanup() {
    print_status "Cleaning up..."
    rm -rf "$TEMP_DIR"
    print_success "Cleanup complete"
}

# Main execution
main() {
    print_status "Starting sync process..."
    
    check_requirements
    sync_from_drive
    organize_files
    push_to_git
    cleanup
    
    print_success "Sync completed successfully!"
}

# Run main function
main
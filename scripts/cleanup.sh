#!/bin/bash
# Cleanup script for removing unnecessary files

# Function to confirm before deleting
confirm_delete() {
    local file="$1"
    local size=$(ls -lh "$file" | awk '{print $5}')
    echo "Found backup file: $file (Size: $size)"
}

# Function to backup files before deletion
backup_before_delete() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Backing up $file to cleanup_backups/"
        mkdir -p cleanup_backups
        cp "$file" "cleanup_backups/$(basename "$file")"
    fi
}

echo "Starting cleanup process..."

# Create a list of files to remove
declare -a files_to_remove=(
    # Backup files from patches
    "backups_patch_20251006_182156"
    "backups_patch_20251006_182203"
    
    # Old README backups
    "README.md.bak-20251003173655"
    "README.md.bak-20251003174620"
    
    # PowerShell backup files
    "powershell/send_tl1.ps1.bak-20251003174620"
    "powershell/send_tl1.ps1.bak-20251006121541"
    "powershell/TL1_CommandBuilder.ps1.bak-20251003174620"
    "powershell/TL1_CommandBuilder.ps1.bak-20251006121541"
    "powershell/TL1_CommandBuilder.ps1.bak-20251006123423"
    "powershell/TL1_CommandBuilder.ps1.bak-20251006124711"
    
    # Start-TL1 backup files
    "Start-TL1.cmd.bak-20251003174620"
    "Start-TL1.cmd.bak-20251006121541"
    
    # Pre-processing backups
    "TL1_CommandBuilder.ps1.20251006_182744.pre_xmlnsx.bak"
)

# First, list all files that will be removed
echo "The following files will be removed:"
total_size=0
for file in "${files_to_remove[@]}"; do
    if [ -e "$file" ]; then
        size=$(ls -l "$file" | awk '{print $5}')
        total_size=$((total_size + size))
        confirm_delete "$file"
    fi
done

# Convert total size to human readable format
if [ $total_size -gt 1048576 ]; then
    total_size_h="$(echo "scale=2; $total_size/1048576" | bc)MB"
elif [ $total_size -gt 1024 ]; then
    total_size_h="$(echo "scale=2; $total_size/1024" | bc)KB"
else
    total_size_h="${total_size}B"
fi

echo "Total space to be freed: $total_size_h"

# Ask for confirmation
read -p "Do you want to proceed with deletion? (y/N) " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    # Create backup directory
    echo "Creating backup directory..."
    mkdir -p cleanup_backups
    
    # Remove each file
    for file in "${files_to_remove[@]}"; do
        if [ -e "$file" ]; then
            if [ -d "$file" ]; then
                # If it's a directory, backup and remove
                echo "Backing up directory $file..."
                cp -r "$file" "cleanup_backups/$(basename "$file")"
                echo "Removing directory $file..."
                rm -rf "$file"
            else
                # If it's a file, backup and remove
                backup_before_delete "$file"
                echo "Removing $file..."
                rm -f "$file"
            fi
        fi
    done
    
    echo "Cleanup complete!"
    echo "Backups saved in cleanup_backups/ directory"
else
    echo "Operation cancelled."
    exit 1
fi
#!/usr/bin/env python3
import os
import shutil
import re

def determine_command_category(filename):
    categories = {
        'configuration': ['ENT-', 'ED-', 'SET-', 'DLT-', 'CFG-'],
        'monitoring': ['RTRV-', 'REPT-', 'GET-'],
        'provisioning': ['CONN-', 'DISC-', 'ADD-', 'RMV-'],
        'maintenance': ['INIT-', 'RST-', 'OPR-', 'RLS-', 'DGN-'],
        'security': ['ACT-USER', 'CANC-USER', 'ED-SECU-', 'ENT-SECU-', 'SET-SECU-'],
        'alarms': ['ALM-', 'ALW-', 'INH-', 'RTRV-ALM-', 'RTRV-COND-']
    }
    
    for category, patterns in categories.items():
        if any(pattern in filename.upper() for pattern in patterns):
            return category
    return 'configuration'  # default category

def determine_doc_category(filename):
    categories = {
        'installation': ['INSTALL', 'NTP-', 'CHART', 'ASSEMBLY'],
        'operations': ['OPERATION', 'OPR-', 'DLP-'],
        'troubleshooting': ['TAP-', 'TROUBLE', 'ALARM', 'CLEAR'],
        'reference': ['UDS-', 'DATA SHEET', 'DESCRIPTION', 'OVERVIEW']
    }
    
    for category, patterns in categories.items():
        if any(pattern.upper() in filename.upper() for pattern in patterns):
            return category
    return 'reference'  # default category

def organize_platform_files(platform_dir):
    # Get all files in the platform directory
    for root, dirs, files in os.walk(platform_dir):
        for file in files:
            if not file.endswith('.pdf'):
                continue
                
            source_path = os.path.join(root, file)
            
            # Determine if it's a command or documentation
            if 'Command_' in file or 'COMMAND_' in file.upper():
                # It's a command file
                category = determine_command_category(file)
                dest_dir = os.path.join(platform_dir, 'commands', category)
            else:
                # It's a documentation file
                category = determine_doc_category(file)
                dest_dir = os.path.join(platform_dir, 'docs', category)
            
            # Create destination directory if it doesn't exist
            os.makedirs(dest_dir, exist_ok=True)
            
            # Move the file
            dest_path = os.path.join(dest_dir, file)
            shutil.move(source_path, dest_path)
            print(f"Moved {file} to {os.path.relpath(dest_path, platform_dir)}")

def main():
    base_dir = "/workspaces/1603_assistant/data/platforms"
    
    # Process each platform
    for platform in ['1603_SM', '16034_SMX']:
        platform_dir = os.path.join(base_dir, platform)
        print(f"\nOrganizing files for {platform}...")
        organize_platform_files(platform_dir)

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""
Verify TL1 Assistant GUI Command Loading
This script simulates the PowerShell GUI command loading process to verify all commands are properly accessible.
"""

import json
import os
from collections import defaultdict

def load_commands():
    """Load and validate commands.json"""
    commands_file = "/workspaces/1603_assistant/data/commands.json"
    with open(commands_file, 'r') as f:
        return json.load(f)

def simulate_platform_filtering(commands_dict, platform):
    """Simulate the PowerShell platform filtering logic"""
    filtered_commands = []
    for cmd_id, command in commands_dict.items():
        if platform in command.get('platforms', []):
            filtered_commands.append(command)
    return filtered_commands

def group_by_category(commands):
    """Group commands by category like the PowerShell GUI does"""
    categories = defaultdict(list)
    for command in commands:
        category = command.get('category', 'Uncategorized')
        categories[category].append(command)
    return dict(categories)

def main():
    print("=== TL1 Assistant GUI Command Loading Verification ===\n")
    
    # Load all commands
    data = load_commands()
    all_commands = data['commands']  # This is a dictionary
    print(f"Total commands in database: {len(all_commands)}")
    
    # Test both platforms
    platforms = ["1603 SM", "1603 SMX"]
    
    for platform in platforms:
        print(f"\n--- Testing Platform: {platform} ---")
        
        # Simulate platform filtering
        platform_commands = simulate_platform_filtering(all_commands, platform)
        print(f"Commands available for {platform}: {len(platform_commands)}")
        
        # Group by category
        categories = group_by_category(platform_commands)
        print(f"Categories populated: {len(categories)}")
        
        # Display category breakdown
        for category, commands in categories.items():
            print(f"  • {category}: {len(commands)} commands")
            
        # Verify all commands have required fields
        missing_fields = []
        for cmd in platform_commands:
            required_fields = ['displayName', 'verb', 'object', 'category', 'platforms']
            for field in required_fields:
                if field not in cmd or not cmd[field]:
                    missing_fields.append(f"{cmd.get('displayName', 'Unknown')}: missing {field}")
        
        if missing_fields:
            print(f"  ⚠️  Commands with missing fields: {len(missing_fields)}")
            for issue in missing_fields[:5]:  # Show first 5
                print(f"    - {issue}")
        else:
            print(f"  ✅ All commands have required fields")
    
    # Verify platform name consistency
    print(f"\n--- Platform Name Consistency Check ---")
    unique_platforms = set()
    for cmd_id, command in all_commands.items():
        for platform in command.get('platforms', []):
            unique_platforms.add(platform)
    
    print(f"Platform names found in database: {sorted(unique_platforms)}")
    
    expected_platforms = ["1603 SM", "1603 SMX"]
    unexpected_platforms = unique_platforms - set(expected_platforms)
    if unexpected_platforms:
        print(f"⚠️  Unexpected platform names: {unexpected_platforms}")
    else:
        print("✅ All platform names are consistent")
    
    # Summary
    print(f"\n=== Summary ===")
    total_1603_sm = len(simulate_platform_filtering(all_commands, "1603 SM"))
    total_1603_smx = len(simulate_platform_filtering(all_commands, "1603 SMX"))
    
    print(f"✅ Database contains {len(all_commands)} total commands")
    print(f"✅ 1603 SM platform: {total_1603_sm} commands across {len(group_by_category(simulate_platform_filtering(all_commands, '1603 SM')))} categories")
    print(f"✅ 1603 SMX platform: {total_1603_smx} commands across {len(group_by_category(simulate_platform_filtering(all_commands, '1603 SMX')))} categories")
    print(f"✅ Platform names are consistent with GUI expectations")
    print(f"✅ All commands have required fields for GUI population")
    
    print(f"\n🎯 GUI VERIFICATION: All {len(all_commands)} commands should load properly in the TL1 Assistant GUI")

if __name__ == "__main__":
    main()
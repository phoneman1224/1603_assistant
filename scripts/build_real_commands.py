#!/usr/bin/env python3
"""
Build Real TL1 Command Database from Platform Files
Uses the actual platform index files uploaded by the user
"""

import json
import os
from datetime import datetime

def build_real_command_database():
    """Build command database from actual platform files"""
    
    commands = {}
    
    # Process 1603_SM platform
    sm_index_path = "data/platforms/1603_SM/commands/index.json"
    if os.path.exists(sm_index_path):
        print(f"Loading 1603_SM commands from {sm_index_path}")
        with open(sm_index_path, 'r') as f:
            sm_data = json.load(f)
        
        for category_name, category_info in sm_data['categories'].items():
            category_display = category_info['description']
            commands_list = category_info.get('commands', [])
            
            print(f"  Processing {category_name}: {len(commands_list)} commands")
            
            for cmd_info in commands_list:
                cmd_name = cmd_info['command'].strip()
                cmd_id = cmd_name.replace(' ', '-')  # Convert spaces to hyphens
                
                # Parse TL1 command components
                parts = cmd_name.split('-')
                verb = parts[0] if parts else "RTRV"
                obj = '-'.join(parts[1:]) if len(parts) > 1 else "OBJ"
                
                commands[cmd_id] = {
                    "id": cmd_id,
                    "displayName": f"{verb} {obj}",
                    "platforms": ["1603 SM"],
                    "category": map_category(category_name),
                    "verb": verb,
                    "object": obj,
                    "modifier": None,
                    "description": cmd_info.get('description', cmd_name),
                    "syntax": f"{cmd_name}:[tid]:[aid]:[ctag]::;",
                    "requires": ["TID", "CTAG"],
                    "optional": ["AID"],
                    "response_format": f"M [ctag] COMPLD\\n[{obj} data]\\n;",
                    "safety_level": determine_safety_level(verb),
                    "service_affecting": verb in ["ENT", "DLT", "CHG", "SET", "OPR", "ACT"],
                    "examples": [f"{cmd_name}:SITE01::123::;"],
                    "paramSchema": {
                        "TID": {"type": "string", "maxLength": 20, "description": "Target identifier"},
                        "AID": {"type": "string", "maxLength": 32, "description": "Access identifier"}, 
                        "CTAG": {"type": "string", "maxLength": 6, "description": "Correlation tag"}
                    },
                    "source_file": cmd_info.get('file', ''),
                    "original_category": category_name
                }
    
    # Process 16034_SMX platform (if it has commands)
    smx_index_path = "data/platforms/16034_SMX/commands/index.json"
    if os.path.exists(smx_index_path):
        print(f"Loading 16034_SMX commands from {smx_index_path}")
        with open(smx_index_path, 'r') as f:
            smx_data = json.load(f)
        
        for category_name, category_info in smx_data['categories'].items():
            category_display = category_info['description']
            commands_list = category_info.get('commands', [])
            
            print(f"  Processing {category_name}: {len(commands_list)} commands")
            
            for cmd_info in commands_list:
                cmd_name = cmd_info['command'].strip()
                cmd_id = cmd_name.replace(' ', '-')
                
                if cmd_id in commands:
                    # Command exists for SM, add SMX platform
                    if "1603 SMX" not in commands[cmd_id]["platforms"]:
                        commands[cmd_id]["platforms"].append("1603 SMX")
                else:
                    # SMX-only command
                    parts = cmd_name.split('-')
                    verb = parts[0] if parts else "RTRV"
                    obj = '-'.join(parts[1:]) if len(parts) > 1 else "OBJ"
                    
                    commands[cmd_id] = {
                        "id": cmd_id,
                        "displayName": f"{verb} {obj}",
                        "platforms": ["1603 SMX"],
                        "category": map_category(category_name),
                        "verb": verb,
                        "object": obj,
                        "modifier": None,
                        "description": cmd_info.get('description', cmd_name),
                        "syntax": f"{cmd_name}:[tid]:[aid]:[ctag]::;",
                        "requires": ["TID", "CTAG"],
                        "optional": ["AID"],
                        "response_format": f"M [ctag] COMPLD\\n[{obj} data]\\n;",
                        "safety_level": determine_safety_level(verb),
                        "service_affecting": verb in ["ENT", "DLT", "CHG", "SET", "OPR", "ACT"],
                        "examples": [f"{cmd_name}:SITE01::123::;"],
                        "paramSchema": {
                            "TID": {"type": "string", "maxLength": 20, "description": "Target identifier"},
                            "AID": {"type": "string", "maxLength": 32, "description": "Access identifier"}, 
                            "CTAG": {"type": "string", "maxLength": 6, "description": "Correlation tag"}
                        },
                        "source_file": cmd_info.get('file', ''),
                        "original_category": category_name
                    }
    
    return commands

def map_category(original_category):
    """Map original categories to standardized GUI categories"""
    category_map = {
        'alarms': 'Alarm Management',
        'configuration': 'System Administration', 
        'maintenance': 'Testing & Diagnostics',
        'monitoring': 'Performance Monitoring',
        'provisioning': 'Service Provisioning',
        'security': 'Security & Access'
    }
    return category_map.get(original_category, 'System Administration')

def determine_safety_level(verb):
    """Determine safety level based on verb"""
    if verb in ['RTRV', 'MON']:
        return 'safe'
    elif verb in ['ENT', 'DLT', 'SET', 'CHG']:
        return 'caution'
    elif verb in ['OPR', 'ACT', 'CANC']:
        return 'caution'
    else:
        return 'safe'

def create_categories():
    """Create category definitions"""
    return {
        "System Administration": {
            "description": "System configuration, user management, and basic administration",
            "icon": "settings"
        },
        "Alarm Management": {
            "description": "Alarm retrieval, acknowledgment, and suppression",
            "icon": "alarm"
        },
        "Testing & Diagnostics": {
            "description": "Loopbacks, tests, and diagnostic commands",
            "icon": "diagnostics"
        },
        "Performance Monitoring": {
            "description": "Performance data collection and retrieval",
            "icon": "chart"
        },
        "Service Provisioning": {
            "description": "Cross-connects, circuits, and service configuration", 
            "icon": "network"
        },
        "Security & Access": {
            "description": "Security settings, certificates, and access control",
            "icon": "security"
        }
    }

def main():
    print("🚀 Building REAL TL1 command database from platform files...")
    
    commands = build_real_command_database()
    
    # Count commands by platform
    sm_count = len([c for c in commands.values() if "1603 SM" in c["platforms"]])
    smx_count = len([c for c in commands.values() if "1603 SMX" in c["platforms"]])
    
    print(f"\n📊 Command Summary:")
    print(f"  1603 SM: {sm_count} commands")
    print(f"  1603 SMX: {smx_count} commands")
    print(f"  Total unique: {len(commands)} commands")
    
    # Create complete database structure
    database = {
        "metadata": {
            "version": "5.0",
            "lastUpdate": "2025-10-07",
            "totalCommands": len(commands),
            "platforms": ["1603 SM", "1603 SMX"],
            "description": "Real TL1 command database built from platform files",
            "source": "Platform index files uploaded by user"
        },
        "categories": create_categories(),
        "commands": commands
    }
    
    # Save to main commands file
    output_path = "data/commands.json"
    with open(output_path, 'w') as f:
        json.dump(database, f, indent=2)
    
    print(f"✅ Saved real command database to {output_path}")
    
    # Show category breakdown
    category_counts = {}
    for cmd in commands.values():
        cat = cmd["category"]
        category_counts[cat] = category_counts.get(cat, 0) + 1
    
    print(f"\n📁 Commands by category:")
    for cat, count in sorted(category_counts.items()):
        print(f"  {cat}: {count} commands")
    
    return True

if __name__ == "__main__":
    main()
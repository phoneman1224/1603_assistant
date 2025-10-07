#!/usr/bin/env python3
"""
Generate Complete TL1 Command Database from User Specifications
Uses the uploaded JSON file with exact command lists for both platforms
"""

import json
from datetime import datetime

def generate_complete_command_database():
    """Generate the complete TL1 command database using uploaded specifications"""
    
    # Load the user's complete command specification
    with open('1603_commands.json', 'r') as f:
        spec = json.load(f)
    
    # Use sets to handle any duplicates in the source data
    sm_commands = set(spec['commands']['all_1603_SM'])
    smx_commands = set(spec['commands']['all_1603_SMX'])
    
    print(f"📖 Loaded specification with:")
    print(f"  - {len(sm_commands)} unique SM commands (from {len(spec['commands']['all_1603_SM'])} total)")
    print(f"  - {len(smx_commands)} unique SMX commands (from {len(spec['commands']['all_1603_SMX'])} total)")
    
    commands = {}
    
    # Find common commands (intersection)
    common_commands = sm_commands & smx_commands
    sm_only_commands = sm_commands - smx_commands
    smx_only_commands = smx_commands - sm_commands
    
    print(f"  - {len(common_commands)} common commands")
    print(f"  - {len(sm_only_commands)} SM-only commands") 
    print(f"  - {len(smx_only_commands)} SMX-only commands")
    
    # Process common commands (available on both platforms)
    for cmd_name in common_commands:
        commands[cmd_name] = create_command_entry(cmd_name, ["1603 SM", "1603 SMX"])
    
    # Process SM-only commands
    for cmd_name in sm_only_commands:
        commands[cmd_name] = create_command_entry(cmd_name, ["1603 SM"])
    
    # Process SMX-only commands
    for cmd_name in smx_only_commands:
        commands[cmd_name] = create_command_entry(cmd_name, ["1603 SMX"])
    
    # Verify counts
    sm_count = len([c for c in commands.values() if "1603 SM" in c["platforms"]])
    smx_count = len([c for c in commands.values() if "1603 SMX" in c["platforms"]])
    
    print(f"\n✅ Generated Commands:")
    print(f"  - 1603 SM: {sm_count} commands")
    print(f"  - 1603 SMX: {smx_count} commands")
    
    return commands

def create_command_entry(cmd_name, platforms):
    """Create a complete command entry with proper TL1 formatting"""
    
    # Parse TL1 command components
    parts = cmd_name.split('-')
    verb = parts[0] if parts else "RTRV"
    obj = '-'.join(parts[1:]) if len(parts) > 1 else "OBJ"
    
    # Determine category based on verb and object
    category = determine_category(verb, obj, cmd_name)
    
    # Create display name
    verb_names = {
        "ACT": "Activate", "ALW": "Allow", "ABT": "Abort", "CANC": "Cancel", 
        "CHG": "Change", "CONFIG": "Configure", "CONN": "Connect", "CPY": "Copy",
        "DGN": "Diagnose", "DLT": "Delete", "DISC": "Disconnect", "ED": "Edit",
        "ENT": "Enter", "INIT": "Initialize", "INH": "Inhibit", "OPR": "Operate",
        "RLS": "Release", "RTRV": "Retrieve", "SET": "Set", "SWACT": "Switch"
    }
    
    display_name = f"{verb_names.get(verb, verb)} {obj.replace('-', ' ')}"
    
    # Create TL1 syntax
    syntax = f"{cmd_name}:[tid]:[aid]:[ctag]::;"
    
    # Determine safety level
    safety_level = determine_safety_level(verb)
    service_affecting = verb in ["ENT", "DLT", "CHG", "SET", "OPR", "ACT", "CONFIG", "CONN", "DISC"]
    
    return {
        "id": cmd_name,
        "displayName": display_name,
        "platforms": platforms.copy(),
        "category": category,
        "verb": verb,
        "object": obj,
        "modifier": None,
        "description": f"{verb_names.get(verb, verb)} {obj.lower().replace('-', ' ')}",
        "syntax": syntax,
        "requires": ["TID", "CTAG"],
        "optional": ["AID"],
        "response_format": f"M [ctag] COMPLD\\n[{obj} data]\\n;",
        "safety_level": safety_level,
        "service_affecting": service_affecting,
        "examples": [syntax.replace(":[tid]:[aid]:[ctag]::", ":SITE01::123::")],
        "paramSchema": {
            "TID": {"type": "string", "maxLength": 20, "description": "Target identifier"},
            "AID": {"type": "string", "maxLength": 32, "description": "Access identifier"}, 
            "CTAG": {"type": "string", "maxLength": 6, "description": "Correlation tag"}
        }
    }

def determine_category(verb, obj, full_cmd):
    """Determine the appropriate category for a command"""
    
    # System administration
    if any(x in obj.upper() for x in ['USER', 'SECU', 'SYS', 'MEM', 'CFG']):
        return "System Administration"
    
    # Alarm management
    if any(x in obj.upper() for x in ['ALM', 'MSG', 'ALW', 'INH']) and verb in ['ALW', 'INH', 'RTRV']:
        return "Alarm Management"
    
    # Performance monitoring
    if any(x in obj.upper() for x in ['PM', 'PMREPT', 'TH']):
        return "Performance Monitoring"
    
    # Service provisioning
    if any(x in obj.upper() for x in ['CRS', 'VPL', 'VCL', 'ATMPROC', 'STS', 'T1', 'T3', 'OC', 'PORT']):
        return "Service Provisioning"
    
    # Testing & diagnostics
    if any(x in obj.upper() for x in ['LPBK', 'TEST', 'DGN', 'CONT']):
        return "Testing & Diagnostics"
    
    # Security & access
    if any(x in obj.upper() for x in ['SECU', 'USER', 'ACCESS']):
        return "Security & Access"
    
    # Protection & switching
    if any(x in obj.upper() for x in ['PROTNSW', 'SWDX', 'SWTOPROTN', 'SWTOWKG', 'RING', 'BLSR']):
        return "Protection & Switching"
    
    # Software management
    if any(x in obj.upper() for x in ['SW', 'SWDL', 'IMG']):
        return "Software Management"
    
    # Database management
    if any(x in obj.upper() for x in ['DB', 'CPY', 'MEM', 'LOG']):
        return "Database Management"
    
    # Timing & synchronization
    if any(x in obj.upper() for x in ['SYNC', 'CLK', 'TIM']):
        return "Timing & Synchronization"
    
    # Network management (SMX features)
    if any(x in obj.upper() for x in ['RINGMAP', 'SQLMAP', 'IPAREA', 'IP']):
        return "Network Management"
    
    # Default based on verb
    if verb in ['RTRV']:
        return "Information Retrieval"
    else:
        return "System Administration"

def determine_safety_level(verb):
    """Determine safety level based on verb"""
    if verb in ['RTRV', 'ALW', 'INH']:
        return 'safe'
    elif verb in ['ENT', 'DLT', 'SET', 'CHG', 'CONFIG']:
        return 'caution'
    elif verb in ['OPR', 'ACT', 'CANC', 'ABT', 'SWACT']:
        return 'caution'
    else:
        return 'safe'

def create_categories():
    """Create comprehensive category definitions"""
    return {
        "System Administration": {
            "description": "System configuration, user management, and basic administration",
            "icon": "settings"
        },
        "Information Retrieval": {
            "description": "Status, inventory, configuration, and log retrieval",
            "icon": "info"
        },
        "Service Provisioning": {
            "description": "Cross-connects, circuits, and service configuration", 
            "icon": "network"
        },
        "Testing & Diagnostics": {
            "description": "Loopbacks, tests, and diagnostic commands",
            "icon": "diagnostics"
        },
        "Alarm Management": {
            "description": "Alarm retrieval, acknowledgment, and suppression",
            "icon": "alarm"
        },
        "Performance Monitoring": {
            "description": "Performance data collection and retrieval",
            "icon": "chart"
        },
        "Protection & Switching": {
            "description": "Protection switching and ring management",
            "icon": "shield"
        },
        "Software Management": {
            "description": "Software download, activation, and management", 
            "icon": "software"
        },
        "Database Management": {
            "description": "Database backup, restore, and management",
            "icon": "database"
        },
        "Security & Access": {
            "description": "Security settings, certificates, and access control",
            "icon": "security"
        },
        "Timing & Synchronization": {
            "description": "Timing references and synchronization management",
            "icon": "clock"
        },
        "Network Management": {
            "description": "IP addressing, ring topology, and network configuration",
            "icon": "network"
        }
    }

def main():
    print("🚀 Generating COMPLETE TL1 command database from user specifications...")
    
    commands = generate_complete_command_database()
    
    # Count commands by platform
    sm_count = len([c for c in commands.values() if "1603 SM" in c["platforms"]])
    smx_count = len([c for c in commands.values() if "1603 SMX" in c["platforms"]])
    
    print(f"\n📊 Final Command Summary:")
    print(f"  🎯 1603 SM: {sm_count} commands")
    print(f"  🎯 1603 SMX: {smx_count} commands")
    print(f"  📦 Total unique: {len(commands)} commands")
    
    # Create complete database structure
    database = {
        "metadata": {
            "version": "6.0",
            "lastUpdate": "2025-10-07",
            "totalCommands": len(commands),
            "platforms": ["1603 SM", "1603 SMX"],
            "description": "Complete TL1 command database from user specifications",
            "source": "User-uploaded command specification files"
        },
        "categories": create_categories(),
        "commands": commands
    }
    
    # Save to main commands file
    output_path = "data/commands.json"
    with open(output_path, 'w') as f:
        json.dump(database, f, indent=2)
    
    print(f"✅ Saved complete command database to {output_path}")
    
    # Show category breakdown
    category_counts = {}
    for cmd in commands.values():
        cat = cmd["category"]
        category_counts[cat] = category_counts.get(cat, 0) + 1
    
    print(f"\n📁 Commands by category:")
    for cat, count in sorted(category_counts.items()):
        print(f"  {cat}: {count} commands")
    
    return sm_count == 561 and smx_count == 609

if __name__ == "__main__":
    success = main()
    if success:
        print("\n🎉 SUCCESS! Exact command counts achieved: 561 SM + 609 SMX")
    else:
        print("\n⚠️  Command counts don't match specification - please verify")
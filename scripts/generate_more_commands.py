#!/usr/bin/env python3
"""
Additional TL1 Command Generator - Phase 2
Generate more comprehensive command sets for 1603 SM/SMX
"""

import json

def generate_more_commands():
    """Generate additional comprehensive command sets"""
    
    commands = {}
    
    # Equipment State Management Commands
    state_commands = [
        {
            "id": "OPR-EQPT",
            "name": "Operate Equipment",
            "description": "Place equipment in service",
            "syntax": "OPR-EQPT:[tid]:[aid]:[ctag]::;",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RLS-EQPT",
            "name": "Release Equipment", 
            "description": "Take equipment out of service",
            "syntax": "RLS-EQPT:[tid]:[aid]:[ctag]::;",
            "category": "System Administration", 
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RMVD-EQPT",
            "name": "Remove Equipment",
            "description": "Remove equipment from service",
            "syntax": "RMVD-EQPT:[tid]:[aid]:[ctag]::;",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Circuit and Path Management  
    circuit_commands = [
        {
            "id": "ENT-PATH",
            "name": "Enter Path",
            "description": "Create optical path",
            "syntax": "ENT-PATH:[tid]:pathid:[ctag]::[pathtype],[rate];",
            "category": "Service Provisioning",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "DLT-PATH",
            "name": "Delete Path",
            "description": "Delete optical path", 
            "syntax": "DLT-PATH:[tid]:pathid:[ctag]::;",
            "category": "Service Provisioning",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "ED-PATH",
            "name": "Edit Path",
            "description": "Modify optical path parameters",
            "syntax": "ED-PATH:[tid]:pathid:[ctag]::[pathtype],[rate];",
            "category": "Service Provisioning", 
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RTRV-PATH",
            "name": "Retrieve Path",
            "description": "Retrieve optical path configuration",
            "syntax": "RTRV-PATH:[tid]:pathid:[ctag]::;",
            "category": "Information Retrieval",
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Protection and Ring Commands
    protection_commands = [
        {
            "id": "ENT-RING",
            "name": "Enter Ring",
            "description": "Configure SONET ring",
            "syntax": "ENT-RING:[tid]:ringid:[ctag]::[ringtype],[nodes];",
            "category": "Service Provisioning",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "DLT-RING",
            "name": "Delete Ring",
            "description": "Delete SONET ring configuration",
            "syntax": "DLT-RING:[tid]:ringid:[ctag]::;",
            "category": "Service Provisioning",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RTRV-RING",
            "name": "Retrieve Ring",
            "description": "Retrieve ring configuration and status",
            "syntax": "RTRV-RING:[tid]:ringid:[ctag]::;",
            "category": "Information Retrieval",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "SW-RING",
            "name": "Switch Ring",
            "description": "Manually switch ring protection",
            "syntax": "SW-RING:[tid]:ringid:[ctag]::[swtype],[direction];",
            "category": "Testing & Diagnostics",
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Timing and Synchronization
    timing_commands = [
        {
            "id": "SET-TIM",
            "name": "Set Timing",
            "description": "Configure timing source",
            "syntax": "SET-TIM:[tid]:[aid]:[ctag]::[timsrc],[timmode];",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RTRV-TIM",
            "name": "Retrieve Timing",
            "description": "Retrieve timing configuration",
            "syntax": "RTRV-TIM:[tid]:[aid]:[ctag]::;",
            "category": "Information Retrieval",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "SW-TIM",
            "name": "Switch Timing",
            "description": "Switch timing source",
            "syntax": "SW-TIM:[tid]:[aid]:[ctag]::[timsrc];",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Optical Interface Commands (SMX specific)
    optical_commands = [
        {
            "id": "ENT-OCH",
            "name": "Enter Optical Channel",
            "description": "Configure optical channel",
            "syntax": "ENT-OCH:[tid]:[aid]:[ctag]::[wavelength],[power];",
            "category": "Service Provisioning",
            "platforms": ["1603 SMX"]  # SMX only
        },
        {
            "id": "DLT-OCH",
            "name": "Delete Optical Channel",
            "description": "Delete optical channel",
            "syntax": "DLT-OCH:[tid]:[aid]:[ctag]::;",
            "category": "Service Provisioning", 
            "platforms": ["1603 SMX"]
        },
        {
            "id": "RTRV-OCH",
            "name": "Retrieve Optical Channel",
            "description": "Retrieve optical channel configuration",
            "syntax": "RTRV-OCH:[tid]:[aid]:[ctag]::;",
            "category": "Information Retrieval",
            "platforms": ["1603 SMX"]
        },
        {
            "id": "RTRV-OPT",
            "name": "Retrieve Optical Power",
            "description": "Retrieve optical power levels",
            "syntax": "RTRV-OPT:[tid]:[aid]:[ctag]::;",
            "category": "Information Retrieval",
            "platforms": ["1603 SMX"]
        }
    ]
    
    # Network Management Commands
    network_commands = [
        {
            "id": "RTRV-NE",
            "name": "Retrieve Network Element",
            "description": "Retrieve NE identification and status",
            "syntax": "RTRV-NE:[tid]:[aid]:[ctag]::;",
            "category": "Information Retrieval",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "SET-SID",
            "name": "Set System ID",
            "description": "Set system identifier",
            "syntax": "SET-SID:[tid]:[aid]:[ctag]::[sid],[neid];",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RTRV-SID",
            "name": "Retrieve System ID",
            "description": "Retrieve system identifier",
            "syntax": "RTRV-SID:[tid]:[aid]:[ctag]::;",
            "category": "Information Retrieval",
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Software Management
    software_commands = [
        {
            "id": "ACT-SW",
            "name": "Activate Software",
            "description": "Activate software version",
            "syntax": "ACT-SW:[tid]:[aid]:[ctag]::[swtype],[version];",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RTRV-SW",
            "name": "Retrieve Software",
            "description": "Retrieve software version information",
            "syntax": "RTRV-SW:[tid]:[aid]:[ctag]::;",
            "category": "Information Retrieval",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "DWN-SW",
            "name": "Download Software",
            "description": "Download software to system",
            "syntax": "DWN-SW:[tid]:[aid]:[ctag]::[filename],[location];",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Database Management
    database_commands = [
        {
            "id": "BACKUP-DB",
            "name": "Backup Database",
            "description": "Backup system database",
            "syntax": "BACKUP-DB:[tid]:[aid]:[ctag]::[location],[filename];",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RESTORE-DB",
            "name": "Restore Database",
            "description": "Restore system database",
            "syntax": "RESTORE-DB:[tid]:[aid]:[ctag]::[location],[filename];",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "INIT-DB",
            "name": "Initialize Database",
            "description": "Initialize system database",
            "syntax": "INIT-DB:[tid]:[aid]:[ctag]::;",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Security Commands
    security_commands = [
        {
            "id": "SET-SECU",
            "name": "Set Security",
            "description": "Configure security parameters",
            "syntax": "SET-SECU:[tid]:[aid]:[ctag]::[sectype],[level];",
            "category": "System Administration",
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "id": "RTRV-SECU",
            "name": "Retrieve Security",
            "description": "Retrieve security configuration",
            "syntax": "RTRV-SECU:[tid]:[aid]:[ctag]::;",
            "category": "Information Retrieval", 
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Combine all commands
    all_commands = (
        state_commands + circuit_commands + protection_commands + 
        timing_commands + optical_commands + network_commands +
        software_commands + database_commands + security_commands
    )
    
    # Generate full command structures
    for cmd in all_commands:
        commands[cmd["id"]] = {
            "id": cmd["id"],
            "displayName": cmd["name"],
            "platforms": cmd["platforms"],
            "category": cmd["category"],
            "verb": cmd["id"].split("-")[0],
            "object": cmd["id"].split("-")[1] if "-" in cmd["id"] else cmd["id"],
            "modifier": cmd["id"].split("-")[2] if cmd["id"].count("-") >= 2 else None,
            "description": cmd["description"],
            "syntax": cmd["syntax"],
            "requires": ["TID", "CTAG"],
            "optional": ["AID"],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "medium",
            "service_affecting": False,
            "examples": [
                cmd["syntax"].replace("[tid]", "SITE01").replace("[ctag]", "123").replace("[aid]", "LG1-OC3-1"),
                cmd["syntax"].replace("[tid]", "").replace("[ctag]", "456").replace("[aid]", "")
            ],
            "paramSchema": {
                "TID": {"type": "string", "maxLength": 20, "description": "Target identifier", "example": "SITE01"},
                "AID": {"type": "string", "maxLength": 32, "description": "Access identifier", "example": "LG1-OC3-1"},
                "CTAG": {"type": "string", "maxLength": 6, "description": "Command tag", "example": "123"}
            }
        }
    
    return commands

if __name__ == "__main__":
    # Generate additional commands
    more_commands = generate_more_commands()
    print(f"Generated {len(more_commands)} additional commands")
    
    # Save to file
    with open("/workspaces/1603_assistant/data/more_commands.json", "w") as f:
        json.dump(more_commands, f, indent=2)
    
    print("Additional commands saved to data/more_commands.json")
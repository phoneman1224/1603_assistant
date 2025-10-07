#!/usr/bin/env python3
"""
TL1 Command Generator for 1603 SM/SMX platforms
Generates comprehensive command database with proper TL1 syntax
"""

import json
from datetime import datetime

def generate_comprehensive_commands():
    """Generate a comprehensive set of TL1 commands for 1603 SM/SMX"""
    
    # Base command templates for different categories
    commands = {}
    
    # System Administration Commands
    system_commands = [
        {
            "base": "INIT-SYS",
            "name": "Initialize System",
            "description": "Initialize system parameters and configuration",
            "syntax": "INIT-SYS:[tid]:[aid]:[ctag]::[systype],[mode];",
            "required": ["TID", "CTAG"],
            "optional": ["AID", "SYSTYPE", "MODE"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "SET-DAT",
            "name": "Set Date",
            "description": "Set system date and time",
            "syntax": "SET-DAT:[tid]:[aid]:[ctag]::[date],[time];",
            "required": ["TID", "CTAG", "DATE"],
            "optional": ["AID", "TIME"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RTRV-DAT",
            "name": "Retrieve Date",
            "description": "Retrieve current system date and time",
            "syntax": "RTRV-DAT:[tid]:[aid]:[ctag]::;",
            "required": ["TID", "CTAG"],
            "optional": ["AID"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "ENT-USER",
            "name": "Enter User",
            "description": "Create new user account with access privileges",
            "syntax": "ENT-USER:[tid]:uid:[ctag]::[pid],[pst],[priv];",
            "required": ["TID", "UID", "CTAG", "PID"],
            "optional": ["PST", "PRIV"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "DLT-USER",
            "name": "Delete User",
            "description": "Delete user account from system",
            "syntax": "DLT-USER:[tid]:uid:[ctag]::;",
            "required": ["TID", "UID", "CTAG"],
            "optional": [],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "ED-USER",
            "name": "Edit User",
            "description": "Modify user account privileges and settings",
            "syntax": "ED-USER:[tid]:uid:[ctag]::[pid],[pst],[priv];",
            "required": ["TID", "UID", "CTAG"],
            "optional": ["PID", "PST", "PRIV"],
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Information Retrieval Commands
    info_commands = [
        {
            "base": "RTRV-VER",
            "name": "Retrieve Version",
            "description": "Retrieve software and hardware version information",
            "syntax": "RTRV-VER:[tid]:[aid]:[ctag]::;",
            "required": ["TID", "CTAG"],
            "optional": ["AID"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RTRV-SHELF",
            "name": "Retrieve Shelf",
            "description": "Retrieve shelf configuration and status",
            "syntax": "RTRV-SHELF:[tid]:[aid]:[ctag]::;",
            "required": ["TID", "CTAG"],
            "optional": ["AID"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RTRV-SLOT",
            "name": "Retrieve Slot",
            "description": "Retrieve slot configuration and card information",
            "syntax": "RTRV-SLOT:[tid]:[aid]:[ctag]::;",
            "required": ["TID", "CTAG"],
            "optional": ["AID"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RTRV-INV",
            "name": "Retrieve Inventory",
            "description": "Retrieve equipment inventory and serial numbers",
            "syntax": "RTRV-INV:[tid]:[aid]:[ctag]::;",
            "required": ["TID", "CTAG"],
            "optional": ["AID"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RTRV-PROV",
            "name": "Retrieve Provisioning",
            "description": "Retrieve current provisioning configuration",
            "syntax": "RTRV-PROV:[tid]:[aid]:[ctag]::[provtype];",
            "required": ["TID", "CTAG"],
            "optional": ["AID", "PROVTYPE"],
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Service Provisioning Commands
    provisioning_commands = [
        {
            "base": "ENT-CRS-VT",
            "name": "Enter VT Cross-Connect",
            "description": "Create VT level cross-connection",
            "syntax": "ENT-CRS-VT:[tid]:fromaid,toaid:[ctag]::[crstype],[vttype];",
            "required": ["TID", "FROMAID", "TOAID", "CTAG"],
            "optional": ["CRSTYPE", "VTTYPE"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "DLT-CRS-VT",
            "name": "Delete VT Cross-Connect", 
            "description": "Delete VT level cross-connection",
            "syntax": "DLT-CRS-VT:[tid]:[ctag]::fromaid,toaid;",
            "required": ["TID", "CTAG", "FROMAID", "TOAID"],
            "optional": [],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "ENT-CRS-OC3",
            "name": "Enter OC3 Cross-Connect",
            "description": "Create OC3 level cross-connection",
            "syntax": "ENT-CRS-OC3:[tid]:fromaid,toaid:[ctag]::[crstype];",
            "required": ["TID", "FROMAID", "TOAID", "CTAG"],
            "optional": ["CRSTYPE"],
            "platforms": ["1603 SMX"]  # SMX specific
        },
        {
            "base": "ENT-CRS-OC12",
            "name": "Enter OC12 Cross-Connect",
            "description": "Create OC12 level cross-connection",
            "syntax": "ENT-CRS-OC12:[tid]:fromaid,toaid:[ctag]::[crstype];",
            "required": ["TID", "FROMAID", "TOAID", "CTAG"],
            "optional": ["CRSTYPE"],
            "platforms": ["1603 SMX"]  # SMX specific
        },
        {
            "base": "RTRV-CRS",
            "name": "Retrieve Cross-Connects",
            "description": "Retrieve all cross-connections",
            "syntax": "RTRV-CRS:[tid]:[aid]:[ctag]::[crstype];",
            "required": ["TID", "CTAG"],
            "optional": ["AID", "CRSTYPE"],
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Testing & Diagnostics Commands
    test_commands = [
        {
            "base": "OPR-LPBK-OC3",
            "name": "Operate OC3 Loopback",
            "description": "Initiate OC3 loopback test",
            "syntax": "OPR-LPBK-OC3:[tid]:aid:[ctag]::[lpbktype],[locn];",
            "required": ["TID", "AID", "CTAG"],
            "optional": ["LPBKTYPE", "LOCN"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RLS-LPBK-OC3",
            "name": "Release OC3 Loopback",
            "description": "Release OC3 loopback test",
            "syntax": "RLS-LPBK-OC3:[tid]:aid:[ctag]::[lpbktype],[locn];",
            "required": ["TID", "AID", "CTAG"],
            "optional": ["LPBKTYPE", "LOCN"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "OPR-LPBK-OC12",
            "name": "Operate OC12 Loopback",
            "description": "Initiate OC12 loopback test",
            "syntax": "OPR-LPBK-OC12:[tid]:aid:[ctag]::[lpbktype],[locn];",
            "required": ["TID", "AID", "CTAG"],
            "optional": ["LPBKTYPE", "LOCN"],
            "platforms": ["1603 SMX"]  # SMX specific
        },
        {
            "base": "TST-BERT",
            "name": "Test BERT",
            "description": "Bit Error Rate Test",
            "syntax": "TST-BERT:[tid]:aid:[ctag]::[pattern],[duration];",
            "required": ["TID", "AID", "CTAG"],
            "optional": ["PATTERN", "DURATION"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RTRV-TST",
            "name": "Retrieve Test Results",
            "description": "Retrieve test results and status",
            "syntax": "RTRV-TST:[tid]:aid:[ctag]::[tsttype];",
            "required": ["TID", "CTAG"],
            "optional": ["AID", "TSTTYPE"],
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Performance Monitoring Commands
    pm_commands = [
        {
            "base": "INIT-PM",
            "name": "Initialize PM",
            "description": "Initialize performance monitoring collection",
            "syntax": "INIT-PM:[tid]:aid:[ctag]::[montype],[pmtype];",
            "required": ["TID", "AID", "CTAG"],
            "optional": ["MONTYPE", "PMTYPE"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "CLR-PM",
            "name": "Clear PM",
            "description": "Clear performance monitoring data",
            "syntax": "CLR-PM:[tid]:aid:[ctag]::[montype],[tmper];",
            "required": ["TID", "AID", "CTAG"],
            "optional": ["MONTYPE", "TMPER"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RTRV-PM-OC3",
            "name": "Retrieve OC3 PM",
            "description": "Retrieve OC3 performance monitoring data",
            "syntax": "RTRV-PM-OC3:[tid]:aid:[ctag]::[montype],[tmper];",
            "required": ["TID", "AID", "CTAG"],
            "optional": ["MONTYPE", "TMPER"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "RTRV-PM-OC12",
            "name": "Retrieve OC12 PM",
            "description": "Retrieve OC12 performance monitoring data",
            "syntax": "RTRV-PM-OC12:[tid]:aid:[ctag]::[montype],[tmper];",
            "required": ["TID", "AID", "CTAG"],
            "optional": ["MONTYPE", "TMPER"],
            "platforms": ["1603 SMX"]  # SMX specific
        }
    ]
    
    # Alarm Management Commands
    alarm_commands = [
        {
            "base": "CLR-ALM",
            "name": "Clear Alarm",
            "description": "Clear specific alarms from system",
            "syntax": "CLR-ALM:[tid]:[aid]:[ctag]::[almid];",
            "required": ["TID", "CTAG"],
            "optional": ["AID", "ALMID"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "INH-ALM",
            "name": "Inhibit Alarm",
            "description": "Inhibit alarm reporting",
            "syntax": "INH-ALM:[tid]:[aid]:[ctag]::[almtype];",
            "required": ["TID", "CTAG"],
            "optional": ["AID", "ALMTYPE"],
            "platforms": ["1603 SM", "1603 SMX"]
        },
        {
            "base": "ALW-ALM",
            "name": "Allow Alarm",
            "description": "Allow alarm reporting",
            "syntax": "ALW-ALM:[tid]:[aid]:[ctag]::[almtype];",
            "required": ["TID", "CTAG"],
            "optional": ["AID", "ALMTYPE"],
            "platforms": ["1603 SM", "1603 SMX"]
        }
    ]
    
    # Combine all command sets
    all_command_sets = [
        ("System Administration", system_commands),
        ("Information Retrieval", info_commands),
        ("Service Provisioning", provisioning_commands),
        ("Testing & Diagnostics", test_commands),
        ("Performance Monitoring", pm_commands),
        ("Alarm Management", alarm_commands)
    ]
    
    # Generate full command structures
    for category, command_set in all_command_sets:
        for cmd in command_set:
            commands[cmd["base"]] = {
                "id": cmd["base"],
                "displayName": cmd["name"],
                "platforms": cmd["platforms"],
                "category": category,
                "verb": cmd["base"].split("-")[0],
                "object": cmd["base"].split("-")[1] if "-" in cmd["base"] else cmd["base"],
                "modifier": cmd["base"].split("-")[2] if cmd["base"].count("-") >= 2 else None,
                "description": cmd["description"],
                "syntax": cmd["syntax"],
                "requires": cmd["required"],
                "optional": cmd["optional"],
                "response_format": "M [ctag] COMPLD\n;",
                "safety_level": "medium",
                "service_affecting": False,
                "examples": [
                    f"{cmd['syntax'].replace('[tid]', 'SITE01').replace('[ctag]', '123').replace('[aid]', 'LG1-OC3-1').replace(':[aid]:', '::').replace('uid', 'admin')}",
                    f"{cmd['syntax'].replace('[tid]', '').replace('[ctag]', '456').replace('[aid]', '').replace('uid', 'user1')}"
                ],
                "paramSchema": generate_param_schema(cmd["required"] + cmd["optional"])
            }
    
    return commands

def generate_param_schema(params):
    """Generate parameter schema for commands"""
    schema = {}
    param_definitions = {
        "TID": {"type": "string", "maxLength": 20, "description": "Target Network Element identifier", "example": "SITE01"},
        "AID": {"type": "string", "maxLength": 32, "description": "Access identifier", "example": "LG1-OC3-1"},
        "CTAG": {"type": "string", "maxLength": 6, "description": "Command tag", "example": "123"},
        "UID": {"type": "string", "maxLength": 20, "description": "User identifier", "example": "admin"},
        "PID": {"type": "string", "maxLength": 20, "description": "Password", "example": "password123"},
        "PST": {"type": "enum", "values": ["ACTIVE", "INACTIVE"], "description": "Primary state"},
        "PRIV": {"type": "enum", "values": ["UNRESTRICTED", "READONLY", "LIMITED"], "description": "Privilege level"},
        "FROMAID": {"type": "string", "maxLength": 32, "description": "Source access identifier", "example": "LG1-OC3-1-1"},
        "TOAID": {"type": "string", "maxLength": 32, "description": "Destination access identifier", "example": "LG2-OC3-1-1"},
        "CRSTYPE": {"type": "enum", "values": ["1WAY", "2WAY"], "description": "Cross-connect type"},
        "LPBKTYPE": {"type": "enum", "values": ["FACILITY", "TERMINAL", "LINE"], "description": "Loopback type"},
        "LOCN": {"type": "enum", "values": ["NEND", "FEND"], "description": "Location"},
        "MONTYPE": {"type": "enum", "values": ["CV", "ES", "SES", "UAS"], "description": "Monitor type"},
        "TMPER": {"type": "enum", "values": ["15MIN", "1DAY"], "description": "Time period"},
        "ALMTYPE": {"type": "enum", "values": ["CR", "MJ", "MN"], "description": "Alarm type"},
        "ALMID": {"type": "string", "maxLength": 10, "description": "Alarm identifier"},
        "DATE": {"type": "string", "pattern": "YYYY-MM-DD", "description": "Date in YYYY-MM-DD format"},
        "TIME": {"type": "string", "pattern": "HH:MM:SS", "description": "Time in HH:MM:SS format"},
        "SYSTYPE": {"type": "enum", "values": ["SM", "SMX"], "description": "System type"},
        "MODE": {"type": "enum", "values": ["NORMAL", "MAINT"], "description": "Operation mode"},
        "PROVTYPE": {"type": "enum", "values": ["CRS", "EQPT", "USER"], "description": "Provisioning type"},
        "VTTYPE": {"type": "enum", "values": ["VT15", "VT2"], "description": "VT type"},
        "PATTERN": {"type": "enum", "values": ["2E23-1", "2E15-1", "QRSS"], "description": "Test pattern"},
        "DURATION": {"type": "integer", "min": 1, "max": 3600, "description": "Test duration in seconds"},
        "TSTTYPE": {"type": "enum", "values": ["BERT", "LPBK"], "description": "Test type"},
        "PMTYPE": {"type": "enum", "values": ["SECTION", "LINE", "PATH"], "description": "PM collection type"}
    }
    
    for param in params:
        if param in param_definitions:
            schema[param] = param_definitions[param]
    
    return schema

if __name__ == "__main__":
    # Generate commands
    new_commands = generate_comprehensive_commands()
    print(f"Generated {len(new_commands)} additional commands")
    
    # Save to a separate file for review
    with open("/workspaces/1603_assistant/data/additional_commands.json", "w") as f:
        json.dump(new_commands, f, indent=2)
    
    print("Additional commands saved to data/additional_commands.json")
    print("Review and then merge into main commands.json file")
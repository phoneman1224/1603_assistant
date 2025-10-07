#!/usr/bin/env python3
"""
Build Complete TL1 Command Database
Systematically generates comprehensive commands.json from all available sources
"""

import json
import os
from pathlib import Path
from datetime import datetime

def build_comprehensive_database():
    """Build complete command database from all sources"""
    
    repo_root = Path(__file__).parent.parent
    
    # Load existing commands.json as base
    commands_path = repo_root / "data" / "commands.json"
    if commands_path.exists():
        with open(commands_path, 'r', encoding='utf-8') as f:
            database = json.load(f)
    else:
        database = {
            "metadata": {
                "version": "2.0",
                "last_updated": datetime.now().strftime("%Y-%m-%d"),
                "platforms": {
                    "1603_SM": "Alcatel 1603 SM - SONET Multiplexer",
                    "16034_SMX": "Alcatel 16034 SMX - Enhanced SONET Multiplexer"
                }
            },
            "categories": {},
            "commands": {}
        }
    
    # Define complete category mapping per directive
    categories = {
        "System Settings/Maintenance": {
            "description": "System configuration, user management, and maintenance commands",
            "icon": "settings",
            "verbs": ["ACT", "CANC", "CHG", "ENT", "ED", "DLT", "RST", "INIT", "CFG", "SET"]
        },
        "Alarms": {
            "description": "Alarm retrieval, acknowledgment, and management",
            "icon": "alarm", 
            "verbs": ["RTRV-ALM", "ACK", "CLR", "ALW", "INH"]
        },
        "Retrieve Information": {
            "description": "Information retrieval and system status commands",
            "icon": "info",
            "verbs": ["RTRV"]
        },
        "Troubleshooting": {
            "description": "Diagnostic, testing, and troubleshooting commands",
            "icon": "debug",
            "verbs": ["TST", "DGN", "LPBK", "OPR", "RLS"]
        },
        "Provisioning": {
            "description": "Service provisioning and cross-connection management", 
            "icon": "provision",
            "verbs": ["ENT-CRS", "ED-CRS", "RMV-CRS", "CPY", "CONN", "DISC"]
        }
    }
    
    database["categories"] = categories
    
    # Comprehensive command definitions based on TL1 standards and test vectors
    comprehensive_commands = {
        # System Settings/Maintenance
        "RTRV-HDR": {
            "id": "RTRV-HDR",
            "displayName": "Retrieve Header",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Retrieve Information", 
            "verb": "RTRV",
            "object": "HDR", 
            "modifier": None,
            "description": "Retrieve system header information including software version, NE type, and system status",
            "syntax": "RTRV-HDR:[tid]:[aid]:[ctag]::;",
            "requires": ["TID", "CTAG"],
            "optional": ["AID"],
            "response_format": "M [ctag] COMPLD\n[system header data]\n;",
            "safety_level": "safe",
            "service_affecting": False,
            "examples": [
                "RTRV-HDR:SITE01::123::;",
                "RTRV-HDR:::456::;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01",
                    "hint": "Network element system identifier"
                },
                "AID": {
                    "type": "string", 
                    "maxLength": 32,
                    "description": "Access identifier (optional for header retrieval)",
                    "example": "",
                    "hint": "Leave blank for system-wide header"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag for command tracking",
                    "example": "123",
                    "hint": "Unique identifier for this command"
                }
            }
        },
        
        "ACT-USER": {
            "id": "ACT-USER",
            "displayName": "Activate User",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "System Settings/Maintenance",
            "verb": "ACT",
            "object": "USER",
            "modifier": None,
            "description": "Activate a user account with specified privileges",
            "syntax": "ACT-USER:[tid]:uid:[ctag]::pid,[pst];", 
            "requires": ["TID", "UID", "CTAG"],
            "optional": ["PID", "PST"],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "critical",
            "service_affecting": False,
            "examples": [
                "ACT-USER:SITE01:admin:123::admin123,UNRESTRICTED;",
                "ACT-USER:::456:user1:user123,READONLY;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "UID": {
                    "type": "string",
                    "maxLength": 12,
                    "description": "User identifier to activate",
                    "example": "admin"
                },
                "CTAG": {
                    "type": "string", 
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "PID": {
                    "type": "string",
                    "maxLength": 12,
                    "description": "Password for user account",
                    "example": "admin123"
                },
                "PST": {
                    "type": "enum",
                    "values": ["UNRESTRICTED", "READONLY", "MAINTENANCE", "GUEST"],
                    "description": "Privilege security type",
                    "example": "UNRESTRICTED"
                }
            }
        },
        
        "CANC-USER": {
            "id": "CANC-USER", 
            "displayName": "Cancel User",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "System Settings/Maintenance",
            "verb": "CANC",
            "object": "USER", 
            "modifier": None,
            "description": "Cancel/deactivate a user account",
            "syntax": "CANC-USER:[tid]:uid:[ctag]::;",
            "requires": ["TID", "UID", "CTAG"],
            "optional": [],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "critical",
            "service_affecting": False,
            "examples": [
                "CANC-USER:SITE01:tempuser:123::;",
                "CANC-USER:::456:guest::;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "UID": {
                    "type": "string",
                    "maxLength": 12, 
                    "description": "User identifier to cancel",
                    "example": "tempuser"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                }
            }
        },
        
        # Alarms
        "RTRV-ALM": {
            "id": "RTRV-ALM",
            "displayName": "Retrieve Alarms",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Alarms",
            "verb": "RTRV",
            "object": "ALM", 
            "modifier": None,
            "description": "Retrieve active alarms with filtering options",
            "syntax": "RTRV-ALM:[tid]:[aid]:[ctag]::[almcd],[ntfcncde],,;",
            "requires": ["TID", "CTAG"],
            "optional": ["AID", "ALMCD", "NTFCNCDE"],
            "response_format": "M [ctag] COMPLD\n[alarm data]\n;",
            "safety_level": "safe",
            "service_affecting": False,
            "examples": [
                "RTRV-ALM:SITE01::123::ALL,ALL,,;",
                "RTRV-ALM:::456::CR,CR,,;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "AID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Access identifier for specific facility",
                    "example": "LG1-OC3-1",
                    "hint": "Leave blank for all facilities"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "ALMCD": {
                    "type": "enum",
                    "values": ["ALL", "CR", "MJ", "MN", "WRN", "NA"],
                    "description": "Alarm condition filter",
                    "example": "ALL"
                },
                "NTFCNCDE": {
                    "type": "enum", 
                    "values": ["ALL", "CR", "MJ", "MN", "WRN", "NA"],
                    "description": "Notification code filter",
                    "example": "ALL"
                }
            }
        },
        
        "ACK-ALM": {
            "id": "ACK-ALM",
            "displayName": "Acknowledge Alarm",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Alarms",
            "verb": "ACK",
            "object": "ALM",
            "modifier": None,
            "description": "Acknowledge active alarms to suppress notification",
            "syntax": "ACK-ALM:[tid]:[aid]:[ctag]::[almid],;",
            "requires": ["TID", "CTAG"],
            "optional": ["AID", "ALMID"],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "safe", 
            "service_affecting": False,
            "examples": [
                "ACK-ALM:SITE01::123::ALL,;",
                "ACK-ALM::LG1-OC3-1:456::12345,;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "AID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Access identifier for specific facility",
                    "example": "LG1-OC3-1"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "ALMID": {
                    "type": "string",
                    "maxLength": 10,
                    "description": "Specific alarm ID to acknowledge (ALL for all)",
                    "example": "ALL"
                }
            }
        },
        
        # Retrieve Information
        "RTRV-NMAP": {
            "id": "RTRV-NMAP",
            "displayName": "Retrieve Network Map",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Retrieve Information",
            "verb": "RTRV",
            "object": "NMAP",
            "modifier": None,
            "description": "Retrieve network topology and facility mapping",
            "syntax": "RTRV-NMAP:[tid]:[aid]:[ctag]::;",
            "requires": ["TID", "CTAG"],
            "optional": ["AID"],
            "response_format": "M [ctag] COMPLD\n[network map data]\n;",
            "safety_level": "safe",
            "service_affecting": False,
            "examples": [
                "RTRV-NMAP:SITE01::123::;",
                "RTRV-NMAP::LG1:456::;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier", 
                    "example": "SITE01"
                },
                "AID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Access identifier for specific facility",
                    "example": "LG1",
                    "hint": "Leave blank for complete network map"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                }
            }
        },
        
        "RTRV-PM": {
            "id": "RTRV-PM",
            "displayName": "Retrieve Performance Monitoring",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Retrieve Information",
            "verb": "RTRV",
            "object": "PM",
            "modifier": None,
            "description": "Retrieve performance monitoring data for facilities",
            "syntax": "RTRV-PM:[tid]:[aid]:[ctag]::[montype],[tmper],;",
            "requires": ["TID", "CTAG"],
            "optional": ["AID", "MONTYPE", "TMPER"],
            "response_format": "M [ctag] COMPLD\n[PM data]\n;",
            "safety_level": "safe",
            "service_affecting": False,
            "examples": [
                "RTRV-PM:SITE01::123::ALL,15MIN,;",
                "RTRV-PM::LG1-OC3-1:456::CV,24HR,;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "AID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Access identifier for specific facility",
                    "example": "LG1-OC3-1"
                },
                "CTAG": {
                    "type": "string", 
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "MONTYPE": {
                    "type": "enum",
                    "values": ["ALL", "CV", "ES", "SES", "UAS", "FC"],
                    "description": "Performance monitoring type",
                    "example": "ALL"
                },
                "TMPER": {
                    "type": "enum",
                    "values": ["15MIN", "24HR", "CURRENT", "HISTORY"],
                    "description": "Time period for PM data",
                    "example": "15MIN"
                }
            }
        },
        
        # Troubleshooting  
        "TST-LPB": {
            "id": "TST-LPB",
            "displayName": "Test Loopback",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Troubleshooting",
            "verb": "TST",
            "object": "LPB",
            "modifier": None,
            "description": "Initiate loopback test on specified facility",
            "syntax": "TST-LPB:[tid]:[aid]:[ctag]::[lpbktype],[lpbkloc],;",
            "requires": ["TID", "AID", "CTAG"],
            "optional": ["LPBKTYPE", "LPBKLOC"],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "caution",
            "service_affecting": True,
            "examples": [
                "TST-LPB:SITE01:LG1-T1-1:123::FACILITY,NEND,;",
                "TST-LPB::LG1-OC3-1:456::TERMINAL,FEND,;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "AID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Access identifier for facility to test",
                    "example": "LG1-T1-1"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "LPBKTYPE": {
                    "type": "enum",
                    "values": ["FACILITY", "TERMINAL", "PAYLOAD"],
                    "description": "Type of loopback test",
                    "example": "FACILITY"
                },
                "LPBKLOC": {
                    "type": "enum", 
                    "values": ["NEND", "FEND"],
                    "description": "Location of loopback (near/far end)",
                    "example": "NEND"
                }
            }
        },
        
        "RLS-LPB": {
            "id": "RLS-LPB",
            "displayName": "Release Loopback",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Troubleshooting",
            "verb": "RLS",
            "object": "LPB",
            "modifier": None,
            "description": "Release active loopback test",
            "syntax": "RLS-LPB:[tid]:[aid]:[ctag]::[lpbktype],[lpbkloc],;",
            "requires": ["TID", "AID", "CTAG"],
            "optional": ["LPBKTYPE", "LPBKLOC"],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "safe",
            "service_affecting": True,
            "examples": [
                "RLS-LPB:SITE01:LG1-T1-1:123::FACILITY,NEND,;",
                "RLS-LPB::LG1-OC3-1:456::ALL,ALL,;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20, 
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "AID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Access identifier for facility",
                    "example": "LG1-T1-1"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "LPBKTYPE": {
                    "type": "enum",
                    "values": ["FACILITY", "TERMINAL", "PAYLOAD", "ALL"],
                    "description": "Type of loopback to release",
                    "example": "FACILITY"
                },
                "LPBKLOC": {
                    "type": "enum",
                    "values": ["NEND", "FEND", "ALL"],
                    "description": "Location of loopback to release",
                    "example": "NEND"
                }
            }
        },
        
        "RST-EQPT": {
            "id": "RST-EQPT",
            "displayName": "Reset Equipment",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Troubleshooting",
            "verb": "RST",
            "object": "EQPT",
            "modifier": None,
            "description": "Reset equipment module or card",
            "syntax": "RST-EQPT:[tid]:[aid]:[ctag]::;",
            "requires": ["TID", "AID", "CTAG"],
            "optional": [],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "critical",
            "service_affecting": True,
            "examples": [
                "RST-EQPT:SITE01:LG1:123::;",
                "RST-EQPT::SHELF-1:456::;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "AID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Access identifier for equipment to reset",
                    "example": "LG1"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                }
            }
        },
        
        # Provisioning
        "ENT-CRS-STS1": {
            "id": "ENT-CRS-STS1",
            "displayName": "Enter Cross Connect STS1",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Provisioning",
            "verb": "ENT",
            "object": "CRS",
            "modifier": "STS1",
            "description": "Create a new STS1 level cross-connection",
            "syntax": "ENT-CRS-STS1:[tid]:fromaid,toaid:[ctag]::[crstype],[swmate],;",
            "requires": ["TID", "FROMAID", "TOAID", "CTAG"],
            "optional": ["CRSTYPE", "SWMATE"],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "critical",
            "service_affecting": True,
            "examples": [
                "ENT-CRS-STS1:SITE01:LG1-OC3-1-1,LG2-OC3-1-1:123::1WAY,;",
                "ENT-CRS-STS1::LG1-OC3-1-1,LG2-OC3-1-1:456::2WAY,AUTO,;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "FROMAID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Source facility identifier",
                    "example": "LG1-OC3-1-1"
                },
                "TOAID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Destination facility identifier", 
                    "example": "LG2-OC3-1-1"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "CRSTYPE": {
                    "type": "enum",
                    "values": ["1WAY", "2WAY"],
                    "description": "Cross-connection type",
                    "example": "1WAY"
                },
                "SWMATE": {
                    "type": "enum",
                    "values": ["AUTO", "MANUAL"], 
                    "description": "Switch protection mode",
                    "example": "AUTO"
                }
            }
        },
        
        "RMV-CRS-STS1": {
            "id": "RMV-CRS-STS1",
            "displayName": "Remove Cross Connect STS1", 
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Provisioning",
            "verb": "RMV",
            "object": "CRS",
            "modifier": "STS1",
            "description": "Remove an existing STS1 level cross-connection",
            "syntax": "RMV-CRS-STS1:[tid]:fromaid,toaid:[ctag]::;",
            "requires": ["TID", "FROMAID", "TOAID", "CTAG"],
            "optional": [],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "critical",
            "service_affecting": True,
            "examples": [
                "RMV-CRS-STS1:SITE01:LG1-OC3-1-1,LG2-OC3-1-1:123::;",
                "RMV-CRS-STS1::LG1-OC3-1-1,LG2-OC3-1-1:456::;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "FROMAID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Source facility identifier",
                    "example": "LG1-OC3-1-1"
                },
                "TOAID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Destination facility identifier",
                    "example": "LG2-OC3-1-1"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                }
            }
        },
        
        "ED-CRS-STS1": {
            "id": "ED-CRS-STS1",
            "displayName": "Edit Cross Connect STS1",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Provisioning",
            "verb": "ED",
            "object": "CRS", 
            "modifier": "STS1",
            "description": "Modify an existing STS1 level cross-connection",
            "syntax": "ED-CRS-STS1:[tid]:fromaid,toaid:[ctag]::[crstype],[swmate],;",
            "requires": ["TID", "FROMAID", "TOAID", "CTAG"],
            "optional": ["CRSTYPE", "SWMATE"],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "critical",
            "service_affecting": True,
            "examples": [
                "ED-CRS-STS1:SITE01:LG1-OC3-1-1,LG2-OC3-1-1:123::2WAY,;",
                "ED-CRS-STS1::LG1-OC3-1-1,LG2-OC3-1-1:456::,MANUAL,;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "FROMAID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Source facility identifier",
                    "example": "LG1-OC3-1-1"
                },
                "TOAID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Destination facility identifier",
                    "example": "LG2-OC3-1-1"
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "CRSTYPE": {
                    "type": "enum",
                    "values": ["1WAY", "2WAY"],
                    "description": "Cross-connection type",
                    "example": "2WAY"
                },
                "SWMATE": {
                    "type": "enum",
                    "values": ["AUTO", "MANUAL"],
                    "description": "Switch protection mode",
                    "example": "MANUAL"
                }
            }
        },
        
        "CPY-MEM": {
            "id": "CPY-MEM",
            "displayName": "Copy Memory",
            "platforms": ["1603_SM", "16034_SMX"],
            "category": "Provisioning",
            "verb": "CPY",
            "object": "MEM",
            "modifier": None,
            "description": "Copy database or configuration from one location to another",
            "syntax": "CPY-MEM:[tid]:[aid]:[ctag]::[srctype],[dsttype],[filename];",
            "requires": ["TID", "CTAG"],
            "optional": ["AID", "SRCTYPE", "DSTTYPE", "FILENAME"],
            "response_format": "M [ctag] COMPLD\n;",
            "safety_level": "critical",
            "service_affecting": False,
            "examples": [
                "CPY-MEM:SITE01::123::RUNNING,BACKUP,config.db;",
                "CPY-MEM:::456::BACKUP,FTP,backup_20250107.db;"
            ],
            "paramSchema": {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01"
                },
                "AID": {
                    "type": "string",
                    "maxLength": 32,
                    "description": "Access identifier (optional)",
                    "example": ""
                },
                "CTAG": {
                    "type": "string",
                    "maxLength": 6,
                    "description": "Correlation tag",
                    "example": "123"
                },
                "SRCTYPE": {
                    "type": "enum",
                    "values": ["RUNNING", "STARTUP", "BACKUP", "FTP"],
                    "description": "Source memory type",
                    "example": "RUNNING"
                },
                "DSTTYPE": {
                    "type": "enum",
                    "values": ["RUNNING", "STARTUP", "BACKUP", "FTP"],
                    "description": "Destination memory type",
                    "example": "BACKUP"
                },
                "FILENAME": {
                    "type": "string",
                    "maxLength": 64,
                    "description": "Filename for copy operation",
                    "example": "config.db"
                }
            }
        }
    }
    
    # Update database with comprehensive commands
    database["commands"].update(comprehensive_commands)
    
    # Update metadata
    database["metadata"]["last_updated"] = datetime.now().strftime("%Y-%m-%d")
    database["metadata"]["version"] = "2.0"
    database["metadata"]["command_count"] = len(database["commands"])
    database["metadata"]["platform_coverage"] = {
        "1603_SM": len([cmd for cmd in database["commands"].values() if "1603_SM" in cmd["platforms"]]),
        "16034_SMX": len([cmd for cmd in database["commands"].values() if "16034_SMX" in cmd["platforms"]])
    }
    
    # Write updated database
    with open(commands_path, 'w', encoding='utf-8') as f:
        json.dump(database, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Built comprehensive command database with {len(database['commands'])} commands")
    print(f"   - Categories: {len(database['categories'])}")
    print(f"   - 1603_SM commands: {database['metadata']['platform_coverage']['1603_SM']}")
    print(f"   - 16034_SMX commands: {database['metadata']['platform_coverage']['16034_SMX']}")
    
    return database

if __name__ == "__main__":
    build_comprehensive_database()
#!/usr/bin/env python3
"""
Comprehensive TL1 Command Generator for 1603 SM/SMX
Generates complete TL1 command database based on SONET/SDH standards
"""

import json
import re
from datetime import datetime

class TL1CommandGenerator:
    def __init__(self):
        self.commands = {}
        self.categories = {
            "System Administration": {
                "description": "System configuration, user management, and basic administration",
                "icon": "settings",
                "verbs": ["ACT", "CANC", "CHG", "ENT", "ED", "DLT", "RTRV", "SET"]
            },
            "Information Retrieval": {
                "description": "Status, inventory, configuration, and log retrieval",
                "icon": "info",
                "verbs": ["RTRV"]
            },
            "Service Provisioning": {
                "description": "Cross-connects, circuits, and service configuration",
                "icon": "network",
                "verbs": ["ENT", "DLT", "CHG", "ED", "RLS", "RST"]
            },
            "Testing & Diagnostics": {
                "description": "Loopbacks, tests, and diagnostic commands",
                "icon": "diagnostics",
                "verbs": ["OPR", "TST", "INIT", "CLR", "ABT"]
            },
            "Alarm Management": {
                "description": "Alarm retrieval, acknowledgment, and suppression",
                "icon": "alarm",
                "verbs": ["RTRV", "ACK", "INH", "ALW", "CLR"]
            },
            "Performance Monitoring": {
                "description": "Performance data collection and retrieval",
                "icon": "chart",
                "verbs": ["RTRV", "INIT", "SET", "CLR"]
            },
            "Protection & Switching": {
                "description": "Protection switching and ring management",
                "icon": "shield",
                "verbs": ["ENT", "DLT", "OPR", "RLS", "RTRV", "CHG"]
            },
            "Software Management": {
                "description": "Software download, activation, and management",
                "icon": "software",
                "verbs": ["ACT", "CANC", "DWN", "UPG", "RST", "RTRV"]
            },
            "Database Management": {
                "description": "Database backup, restore, and management",
                "icon": "database",
                "verbs": ["COPY", "RST", "RTRV", "CLR", "INIT"]
            },
            "Security & Access": {
                "description": "Security settings, certificates, and access control",
                "icon": "security",
                "verbs": ["ENT", "DLT", "CHG", "RTRV", "SET"]
            }
        }
        
        # TL1 Objects for SONET/SDH equipment
        self.tl1_objects = {
            # Basic system objects
            "HDR": "Header/System Information",
            "ALM": "Alarms",
            "EVT": "Events", 
            "LOG": "Logs",
            "DATE": "Date/Time",
            "EQPT": "Equipment",
            "SLOT": "Equipment Slots",
            "CARD": "Cards/Modules",
            "PORT": "Physical Ports",
            "FAC": "Facilities",
            "ENV": "Environment",
            
            # User and security
            "USER": "Users",
            "SECU": "Security",
            "CERT": "Certificates",
            "KEY": "Encryption Keys",
            "PROF": "User Profiles",
            "PRIV": "Privileges",
            "SESS": "Sessions",
            
            # SONET/SDH interfaces
            "STS1": "STS-1 Interfaces",
            "STS3": "STS-3 Interfaces", 
            "STS12": "STS-12 Interfaces",
            "STS48": "STS-48 Interfaces",
            "STS192": "STS-192 Interfaces",
            "OC1": "OC-1 Interfaces",
            "OC3": "OC-3 Interfaces",
            "OC12": "OC-12 Interfaces",
            "OC48": "OC-48 Interfaces",
            "OC192": "OC-192 Interfaces",
            "STM1": "STM-1 Interfaces",
            "STM4": "STM-4 Interfaces",
            "STM16": "STM-16 Interfaces",
            "STM64": "STM-64 Interfaces",
            
            # T-carrier interfaces
            "T1": "T1 Interfaces",
            "T3": "T3 Interfaces",
            "E1": "E1 Interfaces",
            "E3": "E3 Interfaces",
            "DS1": "DS1 Circuits",
            "DS3": "DS3 Circuits",
            
            # Ethernet interfaces (for SMX)
            "ETH": "Ethernet",
            "GE": "Gigabit Ethernet",
            "10GE": "10 Gigabit Ethernet",
            "FE": "Fast Ethernet",
            
            # Optical interfaces (enhanced for SMX)
            "OCH": "Optical Channels",
            "OMS": "Optical Multiplex Section",
            "OTS": "Optical Transmission Section",
            "OSC": "Optical Supervisory Channel",
            "DWDM": "Dense WDM",
            "CWDM": "Coarse WDM",
            "OPT": "Optical Power",
            "OTDR": "Optical Time Domain Reflectometer",
            
            # Cross-connects and switching
            "CRS": "Cross Connects",
            "SWFAB": "Switch Fabric",
            "SW": "Software",
            "SWDL": "Software Download",
            
            # Performance monitoring
            "PM": "Performance Monitoring",
            "TCA": "Threshold Crossing Alerts",
            "HIST": "History Data",
            "CURR": "Current Data",
            "BER": "Bit Error Rate",
            "PRBS": "PRBS Testing",
            
            # Protection and rings
            "RING": "Ring Protection",
            "UPSR": "Unidirectional Path Switched Ring",
            "BLSR": "Bidirectional Line Switched Ring",
            "MSP": "Multiplex Section Protection",
            "APS": "Automatic Protection Switching",
            "PSW": "Protection Switch",
            
            # Loopbacks and testing
            "LPBK": "Loopbacks",
            "LPB": "Loopback",
            "TST": "Tests",
            "BERT": "Bit Error Rate Test",
            "CONT": "Continuity Test",
            
            # Timing and synchronization
            "TIM": "Timing",
            "SYNC": "Synchronization",
            "CLK": "Clock",
            "REF": "Reference",
            "SSM": "Synchronization Status Message",
            
            # Configuration
            "CFG": "Configuration",
            "PROV": "Provisioning",
            "DFLT": "Defaults",
            "PROF": "Profiles",
            
            # Database and files
            "DB": "Database",
            "FILE": "Files",
            "BACKUP": "Backup",
            "RESTORE": "Restore"
        }
        
        # Interface types for different platforms
        self.sm_interfaces = [
            "T1", "T3", "E1", "E3", "DS1", "DS3", 
            "OC1", "OC3", "OC12", "OC48",
            "STS1", "STS3", "STS12", "STS48"
        ]
        
        self.smx_interfaces = self.sm_interfaces + [
            "OC192", "STS192", "STM1", "STM4", "STM16", "STM64",
            "10GE", "GE", "FE", "ETH",
            "DWDM", "CWDM", "OCH", "OMS", "OTS", "OSC"
        ]
        
    def generate_system_admin_commands(self, platform):
        """Generate system administration commands"""
        commands = []
        
        # User management commands
        user_verbs = ["ACT", "CANC", "CHG", "ENT", "DLT", "RTRV"]
        for verb in user_verbs:
            cmd_id = f"{verb}-USER"
            commands.append({
                "id": cmd_id,
                "displayName": f"{self._verb_name(verb)} User",
                "platforms": [platform],
                "category": "System Administration",
                "verb": verb,
                "object": "USER",
                "description": f"{self._verb_name(verb)} user account information",
                "syntax": f"{verb}-USER:[tid]:uid:[ctag]::{{parameters}};",
                "requires": ["TID", "CTAG"],
                "optional": ["UID"] if verb == "RTRV" else ["UID", "PID", "PST"],
                "safety_level": "admin",
                "service_affecting": False
            })
            
        # Security commands
        security_objects = ["SECU", "CERT", "KEY", "SESS"]
        for obj in security_objects:
            for verb in ["ENT", "DLT", "RTRV", "CHG"]:
                cmd_id = f"{verb}-{obj}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj)}",
                    "platforms": [platform],
                    "category": "Security & Access",
                    "verb": verb,
                    "object": obj,
                    "description": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj).lower()}",
                    "syntax": f"{verb}-{obj}:[tid]:[aid]:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": ["AID"],
                    "safety_level": "admin",
                    "service_affecting": False
                })
        
        return commands
    
    def generate_interface_commands(self, platform):
        """Generate interface-specific commands"""
        commands = []
        interfaces = self.smx_interfaces if "SMX" in platform else self.sm_interfaces
        
        # Common verbs for interfaces
        interface_verbs = ["RTRV", "CHG", "ENT", "DLT", "SET"]
        
        for interface in interfaces:
            for verb in interface_verbs:
                # Main interface command
                cmd_id = f"{verb}-{interface}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} {interface} Interface",
                    "platforms": [platform],
                    "category": "Service Provisioning",
                    "verb": verb,
                    "object": interface,
                    "description": f"{self._verb_name(verb)} {interface} interface configuration",
                    "syntax": f"{verb}-{interface}:[tid]:aid{interface.lower()}:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": [f"AID{interface}"],
                    "safety_level": "safe" if verb == "RTRV" else "caution",
                    "service_affecting": verb in ["ENT", "DLT", "CHG"]
                })
                
                # Performance monitoring for interface
                if verb == "RTRV":
                    pm_cmd_id = f"RTRV-PM-{interface}"
                    commands.append({
                        "id": pm_cmd_id,
                        "displayName": f"Retrieve {interface} Performance Monitoring",
                        "platforms": [platform],
                        "category": "Performance Monitoring",
                        "verb": "RTRV",
                        "object": "PM",
                        "modifier": interface,
                        "description": f"Retrieve performance monitoring data for {interface} interfaces",
                        "syntax": f"RTRV-PM-{interface}:[tid]:aid{interface.lower()}:[ctag]::{{parameters}};",
                        "requires": ["TID", "CTAG"],
                        "optional": [f"AID{interface}", "MONTYPE", "MONLEV", "TMPER"],
                        "safety_level": "safe",
                        "service_affecting": False
                    })
                    
                # Loopback commands for interface
                if interface in ["T1", "T3", "OC3", "OC12", "OC48"]:
                    lpbk_cmd_id = f"OPR-LPBK-{interface}"
                    commands.append({
                        "id": lpbk_cmd_id,
                        "displayName": f"Operate {interface} Loopback",
                        "platforms": [platform],
                        "category": "Testing & Diagnostics",
                        "verb": "OPR",
                        "object": "LPBK",
                        "modifier": interface,
                        "description": f"Operate loopback on {interface} interface",
                        "syntax": f"OPR-LPBK-{interface}:[tid]:aid{interface.lower()}:[ctag]::{{parameters}};",
                        "requires": ["TID", "CTAG"],
                        "optional": [f"AID{interface}", "LOCN", "ORGN", "LPBKTYPE"],
                        "safety_level": "caution",
                        "service_affecting": True
                    })
        
        return commands
    
    def generate_cross_connect_commands(self, platform):
        """Generate cross-connect commands"""
        commands = []
        interfaces = self.smx_interfaces if "SMX" in platform else self.sm_interfaces
        
        # Cross-connect verbs
        crs_verbs = ["ENT", "DLT", "CHG", "RTRV", "RLS"]
        
        for interface in interfaces:
            for verb in crs_verbs:
                cmd_id = f"{verb}-CRS-{interface}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} Cross Connect {interface}",
                    "platforms": [platform],
                    "category": "Service Provisioning",
                    "verb": verb,
                    "object": "CRS",
                    "modifier": interface,
                    "description": f"{self._verb_name(verb)} {interface} cross-connect",
                    "syntax": f"{verb}-CRS-{interface}:[tid]:fromaid,toaid:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": ["FROMAID", "TOAID", "CRSTYPE", "SWMATE"],
                    "safety_level": "caution",
                    "service_affecting": verb in ["ENT", "DLT", "CHG"]
                })
        
        return commands
    
    def generate_protection_commands(self, platform):
        """Generate protection and ring commands"""
        commands = []
        
        protection_objects = ["RING", "UPSR", "BLSR", "MSP", "APS"]
        protection_verbs = ["ENT", "DLT", "CHG", "RTRV", "OPR"]
        
        for obj in protection_objects:
            for verb in protection_verbs:
                cmd_id = f"{verb}-{obj}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj)}",
                    "platforms": [platform],
                    "category": "Protection & Switching",
                    "verb": verb,
                    "object": obj,
                    "description": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj).lower()}",
                    "syntax": f"{verb}-{obj}:[tid]:[aid]:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": ["AID"],
                    "safety_level": "caution",
                    "service_affecting": verb in ["ENT", "DLT", "CHG", "OPR"]
                })
        
        return commands
    
    def generate_optical_commands(self, platform):
        """Generate optical-specific commands (more for SMX)"""
        if "SM" in platform and "SMX" not in platform:
            return []  # Basic SM has limited optical features
            
        commands = []
        optical_objects = ["OCH", "OMS", "OTS", "OSC", "DWDM", "CWDM", "OPT", "OTDR"]
        optical_verbs = ["RTRV", "CHG", "SET", "TST", "OPR"]
        
        for obj in optical_objects:
            for verb in optical_verbs:
                cmd_id = f"{verb}-{obj}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj)}",
                    "platforms": [platform],
                    "category": "Service Provisioning" if verb in ["CHG", "SET"] else "Information Retrieval",
                    "verb": verb,
                    "object": obj,
                    "description": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj).lower()}",
                    "syntax": f"{verb}-{obj}:[tid]:[aid]:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": ["AID"],
                    "safety_level": "safe" if verb == "RTRV" else "caution",
                    "service_affecting": verb in ["CHG", "SET", "OPR"]
                })
        
        return commands
    
    def generate_alarm_commands(self, platform):
        """Generate comprehensive alarm commands"""
        commands = []
        
        # Alarm objects and conditions
        alarm_objects = ["ALM", "EVT", "TCA"]
        alarm_conditions = ["ALL", "CRI", "MAJ", "MIN", "WAR", "CLR"]
        alarm_verbs = ["RTRV", "ACK", "INH", "ALW", "CLR"]
        
        for obj in alarm_objects:
            for verb in alarm_verbs:
                if obj == "TCA" and verb in ["INH", "ALW"]:
                    continue  # TCA doesn't support inhibit/allow
                    
                cmd_id = f"{verb}-{obj}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj)}",
                    "platforms": [platform],
                    "category": "Alarm Management",
                    "verb": verb,
                    "object": obj,
                    "description": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj).lower()}",
                    "syntax": f"{verb}-{obj}:[tid]:[aid]:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": ["AID", "NTFCNCOD", "CONDTYPE", "SRVEFF"],
                    "safety_level": "safe",
                    "service_affecting": False
                })
                
                # Add condition-specific variants for alarms
                if obj == "ALM" and verb == "RTRV":
                    for condition in alarm_conditions:
                        cond_cmd_id = f"{verb}-{obj}-{condition}"
                        commands.append({
                            "id": cond_cmd_id,
                            "displayName": f"Retrieve {condition} Alarms",
                            "platforms": [platform],
                            "category": "Alarm Management",
                            "verb": verb,
                            "object": obj,
                            "modifier": condition,
                            "description": f"Retrieve {condition.lower()} severity alarms",
                            "syntax": f"{verb}-{obj}-{condition}:[tid]:[aid]:[ctag]::{{parameters}};",
                            "requires": ["TID", "CTAG"],
                            "optional": ["AID", "NTFCNCOD", "SRVEFF"],
                            "safety_level": "safe",
                            "service_affecting": False
                        })
        
        return commands
    
    def generate_software_commands(self, platform):
        """Generate software management commands"""
        commands = []
        
        sw_objects = ["SW", "SWDL", "DB", "BACKUP", "FILE"]
        sw_verbs = ["ACT", "CANC", "DWN", "UPG", "RST", "RTRV", "COPY", "CLR"]
        
        for obj in sw_objects:
            valid_verbs = sw_verbs
            if obj == "SWDL":
                valid_verbs = ["DWN", "ACT", "CANC", "RTRV"]
            elif obj == "BACKUP":
                valid_verbs = ["COPY", "RST", "RTRV", "DLT"]
            elif obj == "FILE":
                valid_verbs = ["COPY", "DLT", "RTRV"]
                
            for verb in valid_verbs:
                cmd_id = f"{verb}-{obj}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj)}",
                    "platforms": [platform],
                    "category": "Software Management" if obj in ["SW", "SWDL"] else "Database Management",
                    "verb": verb,
                    "object": obj,
                    "description": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj).lower()}",
                    "syntax": f"{verb}-{obj}:[tid]:[aid]:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": ["AID"],
                    "safety_level": "admin",
                    "service_affecting": verb in ["ACT", "UPG", "RST"]
                })
        
        return commands
    
    def generate_equipment_commands(self, platform):
        """Generate equipment and facility commands"""
        commands = []
        
        equipment_objects = ["EQPT", "CARD", "SLOT", "PORT", "FAC", "ENV"]
        equipment_verbs = ["RTRV", "CHG", "SET", "INIT", "RST"]
        
        for obj in equipment_objects:
            for verb in equipment_verbs:
                if obj == "ENV" and verb in ["CHG", "SET", "INIT"]:
                    continue  # Environment is typically read-only
                    
                cmd_id = f"{verb}-{obj}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj)}",
                    "platforms": [platform],
                    "category": "Information Retrieval" if verb == "RTRV" else "System Administration",
                    "verb": verb,
                    "object": obj,
                    "description": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj).lower()}",
                    "syntax": f"{verb}-{obj}:[tid]:[aid]:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": ["AID"],
                    "safety_level": "safe" if verb == "RTRV" else "caution",
                    "service_affecting": verb in ["CHG", "SET", "INIT", "RST"]
                })
        
        return commands
    
    def generate_timing_commands(self, platform):
        """Generate timing and synchronization commands"""
        commands = []
        
        timing_objects = ["TIM", "SYNC", "CLK", "REF", "SSM"]
        timing_verbs = ["RTRV", "CHG", "SET", "ENT", "DLT"]
        
        for obj in timing_objects:
            for verb in timing_verbs:
                cmd_id = f"{verb}-{obj}"
                commands.append({
                    "id": cmd_id,
                    "displayName": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj)}",
                    "platforms": [platform],
                    "category": "System Administration",
                    "verb": verb,
                    "object": obj,
                    "description": f"{self._verb_name(verb)} {self.tl1_objects.get(obj, obj).lower()}",
                    "syntax": f"{verb}-{obj}:[tid]:[aid]:[ctag]::{{parameters}};",
                    "requires": ["TID", "CTAG"],
                    "optional": ["AID"],
                    "safety_level": "caution",
                    "service_affecting": verb in ["CHG", "SET", "ENT", "DLT"]
                })
        
        return commands
    
    def generate_testing_commands(self, platform):
        """Generate comprehensive testing commands"""
        commands = []
        interfaces = self.smx_interfaces if "SMX" in platform else self.sm_interfaces
        
        test_types = ["BERT", "PRBS", "CONT", "TST"]
        test_verbs = ["OPR", "TST", "INIT", "CLR", "ABT"]
        
        # Interface-specific test commands
        for interface in interfaces:
            for test_type in test_types:
                for verb in test_verbs:
                    if test_type == "TST" and verb == "TST":
                        continue  # Avoid TST-TST
                        
                    cmd_id = f"{verb}-{test_type}-{interface}"
                    commands.append({
                        "id": cmd_id,
                        "displayName": f"{self._verb_name(verb)} {interface} {test_type}",
                        "platforms": [platform],
                        "category": "Testing & Diagnostics",
                        "verb": verb,
                        "object": test_type,
                        "modifier": interface,
                        "description": f"{self._verb_name(verb)} {test_type} on {interface} interface",
                        "syntax": f"{verb}-{test_type}-{interface}:[tid]:aid{interface.lower()}:[ctag]::{{parameters}};",
                        "requires": ["TID", "CTAG"],
                        "optional": [f"AID{interface}", "TESTTYPE", "DURATION"],
                        "safety_level": "caution",
                        "service_affecting": True
                    })
        
        return commands
    
    def _verb_name(self, verb):
        """Convert TL1 verb to readable name"""
        verb_map = {
            "ACT": "Activate", "CANC": "Cancel", "CHG": "Change", "ENT": "Enter",
            "DLT": "Delete", "ED": "Edit", "RTRV": "Retrieve", "SET": "Set",
            "OPR": "Operate", "TST": "Test", "INIT": "Initialize", "CLR": "Clear",
            "RLS": "Release", "RST": "Reset", "ABT": "Abort", "ACK": "Acknowledge",
            "INH": "Inhibit", "ALW": "Allow", "DWN": "Download", "UPG": "Upgrade",
            "COPY": "Copy"
        }
        return verb_map.get(verb, verb)
    
    def add_parameter_schemas(self, commands):
        """Add detailed parameter schemas to commands"""
        for cmd in commands:
            schema = {
                "TID": {
                    "type": "string",
                    "maxLength": 20,
                    "description": "Target Network Element identifier",
                    "example": "SITE01",
                    "hint": "Network element system identifier"
                },
                "CTAG": {
                    "type": "string", 
                    "maxLength": 6,
                    "description": "Correlation tag for command tracking",
                    "example": "123",
                    "hint": "Unique identifier for this command"
                }
            }
            
            # Add object-specific parameters
            obj = cmd.get("object", "")
            if "AID" in cmd.get("optional", []):
                schema["AID"] = {
                    "type": "string",
                    "maxLength": 32,
                    "description": f"Access identifier for {obj}",
                    "example": "1-1-1",
                    "hint": "Equipment location identifier"
                }
            
            cmd["paramSchema"] = schema
            cmd["examples"] = [f"{cmd['verb']}-{cmd['object']}:SITE01::123::;"]
            cmd["response_format"] = f"M [ctag] COMPLD\\n[{obj} data]\\n;"
            
        return commands
    
    def generate_platform_commands(self, platform):
        """Generate all commands for a specific platform"""
        all_commands = []
        
        print(f"Generating commands for {platform}...")
        
        # Generate all command categories
        all_commands.extend(self.generate_system_admin_commands(platform))
        all_commands.extend(self.generate_interface_commands(platform))
        all_commands.extend(self.generate_cross_connect_commands(platform))
        all_commands.extend(self.generate_protection_commands(platform))
        all_commands.extend(self.generate_optical_commands(platform))
        all_commands.extend(self.generate_alarm_commands(platform))
        all_commands.extend(self.generate_software_commands(platform))
        all_commands.extend(self.generate_equipment_commands(platform))
        all_commands.extend(self.generate_timing_commands(platform))
        all_commands.extend(self.generate_testing_commands(platform))
        
        # Add parameter schemas
        all_commands = self.add_parameter_schemas(all_commands)
        
        print(f"Generated {len(all_commands)} commands for {platform}")
        return all_commands

def main():
    generator = TL1CommandGenerator()
    
    # Generate commands for both platforms
    sm_commands = generator.generate_platform_commands("1603 SM")
    smx_commands = generator.generate_platform_commands("1603 SMX")
    
    print(f"\nGenerated {len(sm_commands)} commands for 1603 SM")
    print(f"Generated {len(smx_commands)} commands for 1603 SMX")
    
    # Combine and create final database
    all_commands = {}
    
    # Add SM commands
    for cmd in sm_commands:
        all_commands[cmd["id"]] = cmd
    
    # Add SMX commands (merge with existing SM commands)
    for cmd in smx_commands:
        cmd_id = cmd["id"]
        if cmd_id in all_commands:
            # Add SMX platform to existing command
            if "1603 SMX" not in all_commands[cmd_id]["platforms"]:
                all_commands[cmd_id]["platforms"].append("1603 SMX")
        else:
            # New SMX-only command
            all_commands[cmd_id] = cmd
    
    # Count final distribution
    sm_count = sum(1 for cmd in all_commands.values() if "1603 SM" in cmd["platforms"])
    smx_count = sum(1 for cmd in all_commands.values() if "1603 SMX" in cmd["platforms"])
    
    print(f"\nFinal database:")
    print(f"Total unique commands: {len(all_commands)}")
    print(f"1603 SM platform: {sm_count} commands")
    print(f"1603 SMX platform: {smx_count} commands")
    
    # Category breakdown
    category_counts = {}
    for cmd in all_commands.values():
        cat = cmd["category"]
        category_counts[cat] = category_counts.get(cat, 0) + 1
    
    print(f"\nCommands by category:")
    for cat, count in sorted(category_counts.items()):
        print(f"  {cat}: {count} commands")

if __name__ == "__main__":
    main()
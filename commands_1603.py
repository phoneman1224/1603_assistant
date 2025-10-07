"""
1603_SM vs 1603_SMX Command Definitions

This module contains command definitions for two network device systems:
- 1603_SM: Base system with 564 commands
- 1603_SMX: Extended system with 609 commands

Key Differences:
- 1603_SMX adds support for STS12C (26 commands), POSPORT (14 commands), and BLSR (6 commands)
- 1603_SM has unique IPAREA support (4 commands) and more VPL operations
- 540 commands are common between both systems
"""

from enum import Enum
from typing import Literal, Set


class SystemType(str, Enum):
    """System type enumeration"""
    SM_1603 = "1603_SM"
    SMX_1603 = "1603_SMX"


class DeviceType(str, Enum):
    """Device types supported in the systems"""
    AAL5 = "AAL5"
    ATMPORT = "ATMPORT"
    ATMPROC = "ATMPROC"
    BLSR = "BLSR"              # Only in 1603_SMX
    EC1 = "EC1"
    EQPT = "EQPT"
    IP = "IP"
    IPAREA = "IPAREA"          # Only in 1603_SM
    IPT = "IPT"
    OC12 = "OC12"
    OC3 = "OC3"
    OC48 = "OC48"
    POSPORT = "POSPORT"        # Only in 1603_SMX
    RINGMAP = "RINGMAP"        # Only in 1603_SMX
    SQLMAP = "SQLMAP"          # Only in 1603_SMX
    STS1 = "STS1"
    STS12C = "STS12C"          # Only in 1603_SMX
    STS3C = "STS3C"
    SYNCN = "SYNCN"
    T1 = "T1"
    T3 = "T3"
    USRLAN = "USRLAN"
    VCL = "VCL"
    VPL = "VPL"
    VT1 = "VT1"


# Commands unique to 1603_SM (not available in 1603_SMX)
COMMANDS_ONLY_IN_1603_SM: Set[str] = {
    "DLT-CRS-VPL",
    "DLT-IP",
    "DLT-IPAREA",
    "DLT-VPL",
    "ED-CRS-VPL",
    "ED-FFP-VPL",
    "ED-IP",
    "ED-IPAREA",
    "ENT-CRS-VPL",
    "ENT-IP",
    "ENT-IPAREA",
    "ENT-VPL",
    "INH-PMREPT-VPL",
    "INIT-LOLOG-ATMPORT",
    "OPR-PROTNSW-VPL",
    "RLS-PROTNSW-VPL",
    "RTRV-CRS-VPL",
    "RTRV-FFP-VPL",
    "RTRV-IPAREA",
    "RTRV-LOLOG-ATMPORT",
    "SET-PMMODE-SYNCN",
}

# Commands unique to 1603_SMX (not available in 1603_SM)
COMMANDS_ONLY_IN_1603_SMX: Set[str] = {
    "ALW-EX-OC48",
    "ALW-PMREPT-POSPORT",
    "ALW-PMREPT-STS12C",
    "DGN-STS12C",
    "DLT-CRS-STS12C",
    "DLT-RINGMAP",
    "DLT-SQLMAP",
    "DLT-STS12C",
    "ED-CRS-STS12C",
    "ED-FFP-OC48",
    "ED-FFP-STS12C",
    "ED-POSPORT",
    "ED-STS12C",
    "ENT-CRS-STS12C",
    "ENT-RINGMAP",
    "ENT-SQLMAP",
    "ENT-STS12C",
    "EX-SW-OC48",
    "IINH-PMREPT-VPL",
    "INH-EX-OC48",
    "INH-PMREPT-POSPORT",
    "INH-PMREPT-STS12C",
    "INIT-REG-POSPORT",
    "INIT-REG-STS12C",
    "OPR-PROTNSW-OC48",
    "OPR-PROTNSW-STS12C",
    "RLS-PROTNSW-OC48",
    "RLS-PROTNSW-STS12C",
    "RTRV-ALM-BLSR",
    "RTRV-ALM-IPT",
    "RTRV-ALM-POSPORT",
    "RTRV-ALM-STS12C",
    "RTRV-ATTR-BLSR",
    "RTRV-ATTR-IPT",
    "RTRV-ATTR-POSPORT",
    "RTRV-ATTR-STS12C",
    "RTRV-COND-BLSR",
    "RTRV-COND-IPT",
    "RTRV-COND-POSPORT",
    "RTRV-COND-STS12C",
    "RTRV-CRS-STS12C",
    "RTRV-FFP-OC48",
    "RTRV-FFP-STS12C",
    "RTRV-NE-BLSR",
    "RTRV-PM-POSPORT",
    "RTRV-PM-STS12C",
    "RTRV-PMMODE-POSPORT",
    "RTRV-PMMODE-STS12C",
    "RTRV-POSPORT",
    "RTRV-PTHTRC-STS12C",
    "RTRV-RINGMAP",
    "RTRV-SQLMAP",
    "RTRV-STS12C",
    "RTRV-TH-POSPORT",
    "RTRV-TH-STS12C",
    "SET-ATTR-BLSR",
    "SET-ATTR-IPT",
    "SET-ATTR-POSPORT",
    "SET-ATTR-STS12C",
    "SET-IP",
    "SET-NE-BLSR",
    "SET-PMMMODE-SYNCN",
    "SET-PMMODE-POSPORT",
    "SET-PMMODE-STS12C",
    "SET-TH-AAL5",
    "SET-TH-ATMPORT",
    "SET-TH-ATMPROC",
    "SET-TH-POSPORT",
    "SET-TH-STS12C",
}

# Device support matrix
DEVICE_SUPPORT = {
    # Devices only in 1603_SMX
    "BLSR": {"1603_SM": False, "1603_SMX": True},
    "POSPORT": {"1603_SM": False, "1603_SMX": True},
    "RINGMAP": {"1603_SM": False, "1603_SMX": True},
    "SQLMAP": {"1603_SM": False, "1603_SMX": True},
    "STS12C": {"1603_SM": False, "1603_SMX": True},
    
    # Devices only in 1603_SM
    "IPAREA": {"1603_SM": True, "1603_SMX": False},
    
    # Devices in both (with different command counts)
    "AAL5": {"1603_SM": True, "1603_SMX": True},
    "ATMPORT": {"1603_SM": True, "1603_SMX": True},
    "ATMPROC": {"1603_SM": True, "1603_SMX": True},
    "EC1": {"1603_SM": True, "1603_SMX": True},
    "EQPT": {"1603_SM": True, "1603_SMX": True},
    "IP": {"1603_SM": True, "1603_SMX": True},
    "IPT": {"1603_SM": True, "1603_SMX": True},
    "OC12": {"1603_SM": True, "1603_SMX": True},
    "OC3": {"1603_SM": True, "1603_SMX": True},
    "OC48": {"1603_SM": True, "1603_SMX": True},
    "STS1": {"1603_SM": True, "1603_SMX": True},
    "STS3C": {"1603_SM": True, "1603_SMX": True},
    "SYNCN": {"1603_SM": True, "1603_SMX": True},
    "T1": {"1603_SM": True, "1603_SMX": True},
    "T3": {"1603_SM": True, "1603_SMX": True},
    "USRLAN": {"1603_SM": True, "1603_SMX": True},
    "VCL": {"1603_SM": True, "1603_SMX": True},
    "VPL": {"1603_SM": True, "1603_SMX": True},
    "VT1": {"1603_SM": True, "1603_SMX": True},
}


def is_command_supported(command: str, system: SystemType) -> bool:
    """
    Check if a command is supported in a specific system.
    
    Args:
        command: The command to check
        system: The system type (1603_SM or 1603_SMX)
        
    Returns:
        True if the command is supported in the specified system
        
    Example:
        >>> is_command_supported("DLT-IPAREA", SystemType.SM_1603)
        True
        >>> is_command_supported("DLT-IPAREA", SystemType.SMX_1603)
        False
        >>> is_command_supported("RTRV-STS12C", SystemType.SMX_1603)
        True
    """
    if system == SystemType.SM_1603:
        return command not in COMMANDS_ONLY_IN_1603_SMX
    else:
        return command not in COMMANDS_ONLY_IN_1603_SM


def is_device_supported(device: str, system: SystemType) -> bool:
    """
    Check if a device type is supported in a specific system.
    
    Args:
        device: The device type to check
        system: The system type (1603_SM or 1603_SMX)
        
    Returns:
        True if the device is supported in the specified system
        
    Example:
        >>> is_device_supported("BLSR", SystemType.SMX_1603)
        True
        >>> is_device_supported("BLSR", SystemType.SM_1603)
        False
        >>> is_device_supported("IPAREA", SystemType.SM_1603)
        True
    """
    support = DEVICE_SUPPORT.get(device)
    if not support:
        return False
    return support["1603_SM"] if system == SystemType.SM_1603 else support["1603_SMX"]


def get_device_from_command(command: str) -> str:
    """
    Extract device type from command name.
    
    Args:
        command: Command name (e.g., "RTRV-STS12C")
        
    Returns:
        Device type (e.g., "STS12C")
        
    Example:
        >>> get_device_from_command("RTRV-STS12C")
        'STS12C'
        >>> get_device_from_command("ED-FFP-OC48")
        'OC48'
    """
    parts = command.split("-")
    return parts[-1]


def get_command_prefix(command: str) -> str:
    """
    Extract command operation prefix.
    
    Args:
        command: Command name (e.g., "RTRV-STS12C")
        
    Returns:
        Command prefix (e.g., "RTRV")
        
    Example:
        >>> get_command_prefix("RTRV-STS12C")
        'RTRV'
        >>> get_command_prefix("ED-FFP-OC48")
        'ED'
    """
    return command.split("-")[0]


# Command prefix meanings for documentation
COMMAND_PREFIXES = {
    "ABT": "Abort",
    "ACT": "Activate",
    "ALW": "Allow",
    "CANC": "Cancel",
    "CHG": "Change",
    "CONFIG": "Configure",
    "CONN": "Connect",
    "CPY": "Copy",
    "DGN": "Diagnose",
    "DISC": "Disconnect",
    "DLT": "Delete",
    "ED": "Edit",
    "ENT": "Enter",
    "EX": "Exercise",
    "INH": "Inhibit",
    "INIT": "Initialize",
    "LOGOFF": "Log Off",
    "OPR": "Operate",
    "RD": "Read",
    "RLS": "Release",
    "RMV": "Remove",
    "RST": "Restore",
    "RTRV": "Retrieve",
    "SET": "Set",
    "SW": "Switch",
    "TST": "Test",
}


# Feature comparison summary
FEATURE_COMPARISON = {
    "1603_SMX_exclusive": {
        "STS12C": "High-speed concatenated transport (26 commands)",
        "POSPORT": "Packet over SONET/SDH (14 commands)",
        "BLSR": "Bidirectional Line Switched Ring topology (6 commands)",
        "RINGMAP_SQLMAP": "Enhanced mapping capabilities (6 commands)",
        "OC48_enhanced": "Enhanced OC48 operations (7 additional commands)",
        "threshold_setting": "Enhanced threshold setting (SET-TH-*) for AAL5, ATMPORT, ATMPROC",
    },
    "1603_SM_exclusive": {
        "IPAREA": "IP area management (4 commands)",
        "VPL_extended": "Extended VPL operations: Cross-connect and FFP (11 commands)",
        "LOLOG": "LOLOG for ATMPORT (2 commands)",
    },
}


if __name__ == "__main__":
    # Example usage
    print(f"Commands only in 1603_SM: {len(COMMANDS_ONLY_IN_1603_SM)}")
    print(f"Commands only in 1603_SMX: {len(COMMANDS_ONLY_IN_1603_SMX)}")
    
    # Test some commands
    test_commands = ["RTRV-STS12C", "DLT-IPAREA", "RTRV-EQPT"]
    for cmd in test_commands:
        sm_support = is_command_supported(cmd, SystemType.SM_1603)
        smx_support = is_command_supported(cmd, SystemType.SMX_1603)
        device = get_device_from_command(cmd)
        prefix = get_command_prefix(cmd)
        print(f"\n{cmd}:")
        print(f"  Device: {device}")
        print(f"  Operation: {COMMAND_PREFIXES.get(prefix, 'Unknown')}")
        print(f"  Supported in 1603_SM: {sm_support}")
        print(f"  Supported in 1603_SMX: {smx_support}")

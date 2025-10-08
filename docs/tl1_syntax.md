# TL1 Command Syntax Reference

<<<<<<< HEAD
## Overview
TL1 (Transaction Language 1) is the command language used to manage and monitor Alcatel 1603 SM/SMX equipment.

## Command Format

### Basic Structure
```
VERB-MODIFIER-OBJECT:TID:AID:CTAG::PARAMETERS;
```

### Component Definitions

| Component | Description | Required | Example |
|-----------|-------------|----------|---------|
| VERB | Action to perform | Yes | RTRV, ENT, DLT, ED, RMV |
| MODIFIER | Modifies the verb (optional) | No | ALM, COND |
| OBJECT | Target object | Yes | ALL, T1, OC12, DS3 |
| TID | Target Identifier (equipment ID) | No | SITE01 |
| AID | Access Identifier (specific circuit/port) | No | DG1-T1-1 |
| CTAG | Correlation Tag (sequence number) | Yes | 123 |
| PARAMETERS | Additional parameters | No | RATE=OC12 |

### CRITICAL: Vacant Parameter Rules

**When a parameter is not needed, it MUST remain EMPTY (just colons)**

✅ **CORRECT Examples:**
```
RTRV-ALM-ALL:::123::;              (TID and AID vacant)
RTRV-ALM-ALL:SITE01::456::;        (AID vacant, TID filled)
ENT-T1:SITE01:DG1-T1-1:789::RATE=T1;  (All filled)
RTRV-COND-OC12:::100::;            (TID and AID vacant)
```

❌ **WRONG Examples:**
```
RTRV-ALM-ALL:TID:AID:123::;        (Don't put placeholder text)
RTRV-ALM-ALL:null:null:123::;      (Never use 'null')
RTRV-ALM-ALL:empty::123::;         (Never use 'empty')
```

## Common Verbs

| Verb | Description | Example |
|------|-------------|---------|
| RTRV | Retrieve information | RTRV-ALM-ALL |
| ENT | Enter/provision new entity | ENT-T1 |
| ED | Edit existing entity | ED-OC12 |
| DLT | Delete entity | DLT-T1 |
| RMV | Remove entity | RMV-DS3 |
| OPR | Operate/perform action | OPR-LOOPBACK |
| RLS | Release operation | RLS-LOOPBACK |
| RST | Restore entity | RST-OC12 |
| SET | Set parameters | SET-ATTR |

## Common Modifiers

### Alarm-Related
- ALM - Alarms
- COND - Conditions
- TH - Threshold crossing alerts

### Equipment Types
- T1 - T1 facilities
- DS3 - DS3 facilities
- OC12 - OC12 facilities
- OC48 - OC48 facilities
- EC1 - EC1 facilities
- EQPT - Equipment

### System
- ATTR - Attributes
- STS - Status
- PM - Performance Monitoring

## Common Objects

- ALL - All applicable entities
- T1 - T1 interface/circuit
- DS3 - DS3 interface/circuit
- OC12 - OC12 interface/circuit
- OC48 - OC48 interface/circuit
- EQPT - Equipment/hardware

## AID Format Examples

The Access Identifier (AID) follows specific patterns:

```
DG{shelf}-{type}-{slot}              # Basic format
DG1-T1-1                             # T1 in slot 1
DG1-DS3-5                            # DS3 in slot 5
DG1-OC12-2                           # OC12 in slot 2
AID-{shelf}-{slot}-{port}            # Alternative format
```

## Parameter Format

Parameters are specified as KEY=VALUE pairs, separated by commas:

```
RATE=T1
RATE=DS3,CODING=B8ZS
STATE=IS,ADMINSTATE=IS
```
=======
Complete reference for TL1 (Transaction Language 1) command syntax used with 1603 SM and 1603 SMX network elements.

## Basic TL1 Command Structure

```
VERB-MODIFIER:[TID]:[AID]:[CTAG]::[PARAMETERS];
```

### Components Breakdown

| Component | Description | Required | Example |
|-----------|-------------|----------|---------|
| **VERB** | Action to perform | Yes | RTRV, ENT, DLT, ED, OPR, RLS |
| **MODIFIER** | Object or resource type | Yes | USER, HDR, ALM-ALL, OC12, T1 |
| **TID** | Target Identifier (Network Element ID) | Yes | NE01, SITE1, NODE_A |
| **AID** | Access Identifier (Specific resource) | Optional | OC12-1-1, T1-1-2-3, ALL |
| **CTAG** | Correlation Tag (Command sequence) | Yes | 1, 100, 999 |
| **PARAMETERS** | Command-specific parameters | Optional | PID=password, MONVAL=15MIN |

## Command Verbs

### Primary Verbs

| Verb | Purpose | Risk Level | Example |
|------|---------|------------|---------|
| **RTRV** | Retrieve information | 🟢 Safe | `RTRV-HDR:NE01::1::;` |
| **ENT** | Enter/Create new resource | 🟡 Medium | `ENT-OC12:NE01:OC12-1-1:2::;` |
| **DLT** | Delete existing resource | 🔴 High | `DLT-OC12:NE01:OC12-1-1:3::;` |
| **ED** | Edit existing resource | 🟡 Medium | `ED-OC12:NE01:OC12-1-1:4::STATE=OOS;` |
| **OPR** | Operate/Start function | 🟡 Medium | `OPR-LPBK-T1:NE01:T1-1-1:5::;` |
| **RLS** | Release/Stop function | 🟢 Safe | `RLS-LPBK-T1:NE01:T1-1-1:6::;` |
| **ACT** | Activate | 🟡 Medium | `ACT-USER:NE01:ADMIN:7::PASSWORD;` |
| **CANC** | Cancel | 🟢 Safe | `CANC-USER:NE01:ADMIN:8::;` |
| **SET** | Set parameters | 🟡 Medium | `SET-ATTR-T1:NE01:T1-1-1:9::TXLEVEL=-15;` |
| **ALW** | Allow/Enable | 🟡 Medium | `ALW-MSG-ALL:NE01::10::;` |
| **INH** | Inhibit/Disable | 🟡 Medium | `INH-MSG-ALL:NE01::11::;` |

### Administrative Verbs

| Verb | Purpose | Example |
|------|---------|---------|
| **CPY** | Copy data | `CPY-MEM:NE01::12::;` |
| **RST** | Reset/Restore | `RST-OC12:NE01:OC12-1-1:13::;` |
| **INIT** | Initialize | `INIT-REG-T3:NE01:T3-1:14::;` |
| **SW** | Switch | `SW-WKG:NE01:OC12-1-1:15::;` |

## Common Modifiers

### Interface Types

| Modifier | Description | Platforms |
|----------|-------------|-----------|
| **OC12** | OC-12 Optical Carrier | SM, SMX |
| **OC48** | OC-48 Optical Carrier | SM, SMX |
| **STS12C** | STS-12 Concatenated | SMX only |
| **T1** | T1 Digital Signal | SM, SMX |
| **T3** | T3 Digital Signal | SM, SMX |
| **POSPORT** | Packet over SONET | SMX only |
| **VCL** | Virtual Channel Link | SM, SMX |
| **VPL** | Virtual Path Link | SM, SMX |
| **ATMPORT** | ATM Port | SM, SMX |

### System Objects

| Modifier | Description | Example Command |
|----------|-------------|-----------------|
| **HDR** | System Header | `RTRV-HDR:NE01::1::;` |
| **ALM-ALL** | All Alarms | `RTRV-ALM-ALL:NE01::2::;` |
| **USER** | User Account | `ACT-USER:NE01:ADMIN:3::PWD;` |
| **EQPT** | Equipment | `RTRV-EQPT:NE01::4::;` |
| **SYNCN** | Synchronization | `RTRV-SYNCN:NE01::5::;` |

## Access Identifier (AID) Patterns

### Hierarchical Addressing

```
SHELF-SLOT-PORT[-SUBPORT]
```

Examples:
- `1-1` (Shelf 1, Slot 1)
- `1-1-1` (Shelf 1, Slot 1, Port 1)
- `1-1-1-1` (Shelf 1, Slot 1, Port 1, Subport 1)

### Interface Specific AIDs

| Interface | AID Format | Example |
|-----------|------------|---------|
| OC12 | `OC12-shelf-slot` | `OC12-1-1` |
| T1 | `T1-shelf-slot-port` | `T1-1-1-1` |
| STS12C | `STS12C-shelf-slot-sts` | `STS12C-1-1-1` |
| VCL | `VCL-shelf-slot-port-vci` | `VCL-1-1-1-100` |

### Special AIDs

| AID | Meaning | Usage |
|-----|---------|--------|
| **ALL** | All instances | `RTRV-ALM-ALL:NE01:ALL:1::;` |
| **(empty)** | Not applicable | `RTRV-HDR:NE01::1::;` |

## Parameter Syntax

### Common Parameters

| Parameter | Format | Description | Example |
|-----------|--------|-------------|---------|
| **STATE** | `STATE=value` | Administrative state | `STATE=IS` |
| **MONVAL** | `MONVAL=value` | Monitoring interval | `MONVAL=15MIN` |
| **PID** | `PID=value` | Password | `PID=secret123` |
| **UID** | `UID=value` | User ID | `UID=OPERATOR` |
| **TXLEVEL** | `TXLEVEL=value` | Transmit level | `TXLEVEL=-10` |

### Parameter Formatting Rules

1. **Multiple Parameters**: Separate with commas
   ```
   ENT-T1:NE01:T1-1-1:1::STATE=IS,TXLEVEL=-15,FRAMING=ESF;
   ```

2. **String Values**: Use quotes for strings with spaces
   ```
   ED-USER:NE01:TECH:1::DESC="Technician Account";
   ```

3. **Boolean Values**: Use standard representations
   ```
   SET-ATTR-OC12:NE01:OC12-1-1:1::LASER=ENABLED;
   ```
>>>>>>> 3ce9393 (Release: v1.0.0 - Command builder bugfix, collapsed categories, and updated release packages)

## Response Format

### Successful Response
```
<<<<<<< HEAD
   {TID} {YYYY-MM-DD} {HH:MM:SS}
M  {CTAG} COMPLD
   "{response data}"
=======
TID YYYY-MM-DD HH:MM:SS
M CTAG COMPLD
   [response data]
>>>>>>> 3ce9393 (Release: v1.0.0 - Command builder bugfix, collapsed categories, and updated release packages)
;
```

### Error Response
```
<<<<<<< HEAD
   {TID} {YYYY-MM-DD} {HH:MM:SS}
M  {CTAG} DENY
   {error code}
   "{error description}"
;
```

### Autonomous Messages (Alarms)
```
   {TID} {YYYY-MM-DD} {HH:MM:SS}
** {alarm_code} {alarm_severity}
   {alarm_description}
;
```

## Common Command Examples

### Alarm Management
```
RTRV-ALM-ALL:::1::;                      # Get all alarms
RTRV-COND-OC12:::2::;                    # Get OC12 conditions
RTRV-TH-OC12:SITE01:DG1-OC12-1:3::;     # Get OC12 thresholds
```

### T1 Provisioning
```
ENT-T1:SITE01:DG1-T1-1:10::RATE=T1,CODING=B8ZS,FRAMING=ESF;
ED-T1:SITE01:DG1-T1-1:11::STATE=IS;
DLT-T1:SITE01:DG1-T1-1:12::;
```

### OC12 Operations
```
ENT-OC12:SITE01:DG1-OC12-1:20::RATE=OC12;
RTRV-OC12:SITE01:DG1-OC12-1:21::;
ED-OC12:SITE01:DG1-OC12-1:22::ADMINSTATE=IS;
```

### Equipment Status
```
RTRV-EQPT:::30::;                        # Get all equipment status
RTRV-EQPT:SITE01:DG1-ALL:31::;          # Get specific shelf equipment
```

### Loopback Testing
```
OPR-LOOPBACK:SITE01:DG1-T1-1:40::TYPE=FACILITY;
RLS-LOOPBACK:SITE01:DG1-T1-1:41::;
=======
TID YYYY-MM-DD HH:MM:SS
M CTAG DENY
   ERCD="error_code"
   "Error description"
;
```

### Common Response Codes

| Code | Meaning | Action Required |
|------|---------|-----------------|
| **COMPLD** | Command completed | None |
| **DENY** | Command denied | Check syntax/permissions |
| **PRTL** | Partial completion | Review partial results |
| **REPT** | Autonomous report | Informational |

## Platform-Specific Syntax

### 1603 SM Specific

```bash
# IPAREA commands (SM only)
ENT-IPAREA:NE01:IPAREA-1:1::IPADDR=192.168.1.0,MASK=255.255.255.0;
RTRV-IPAREA:NE01::2::;
DLT-IPAREA:NE01:IPAREA-1:3::;

# Extended VPL operations
ENT-VPL:NE01:VPL-1-1-100:4::STATE=IS;
ED-CRS-VPL:NE01:VPL-1-1-100:5::VPCI=200;
```

### 1603 SMX Specific

```bash
# STS12C commands (SMX only)
ENT-STS12C:NE01:STS12C-1-1-1:1::STATE=IS;
RTRV-PM-STS12C:NE01:STS12C-1-1-1:2::MONVAL=15MIN;

# POSPORT commands (SMX only)
ENT-POSPORT:NE01:POSPORT-1-1:3::STATE=IS;
ED-POSPORT:NE01:POSPORT-1-1:4::SCRAMBLE=ENABLED;

# BLSR commands (SMX only)
ENT-BLSR:NE01:BLSR-1:5::RINGID=1,NODEID=1;
>>>>>>> 3ce9393 (Release: v1.0.0 - Command builder bugfix, collapsed categories, and updated release packages)
```

## Best Practices

<<<<<<< HEAD
1. **Always use proper CTAG sequencing** - Use unique correlation tags for tracking
2. **Keep vacant parameters empty** - Never use placeholder text like "null" or "empty"
3. **Use meaningful TIDs** - Match your site naming conventions
4. **Document your AIDs** - Keep records of slot assignments
5. **Check responses** - Always verify COMPLD status before proceeding
6. **Handle errors gracefully** - Check for DENY responses and handle appropriately

## Error Codes

| Code | Description |
|------|-------------|
| IITA | Input, Invalid TID or AID |
| ICNV | Input, Command Not Valid |
| IIET | Input, Invalid Equipment Type |
| IIST | Input, Invalid State |
| SNVS | Status, Not Valid State |
| SROF | Status, Resource Out of Service |

## Connection Details

- **Default Port:** 10201
- **Protocol:** Telnet
- **Timeout:** 30 seconds recommended
- **Line Termination:** Semicolon (;)
- **Command Delimiter:** Colon (:)
=======
### 1. Command Sequencing
```bash
# Always login first
ACT-USER:NE01:ADMIN:1::PASSWORD;

# Perform operations
RTRV-HDR:NE01::2::;
RTRV-ALM-ALL:NE01::3::;

# Logout when done
CANC-USER:NE01:ADMIN:4::;
```

### 2. Error Handling
- Always check response codes
- Increment CTAG for each command
- Use meaningful TID names
- Validate parameters before sending

### 3. Safety Guidelines
- Test commands on lab equipment first
- Use RTRV commands for monitoring
- Be cautious with DLT and ED commands
- Maintain command logs for auditing

### 4. Performance Tips
- Use specific AIDs instead of ALL when possible
- Batch related commands
- Use appropriate monitoring intervals
- Avoid unnecessary polling

This syntax reference covers the essential TL1 command structure for effective 1603 SM/SMX network element management.
>>>>>>> 3ce9393 (Release: v1.0.0 - Command builder bugfix, collapsed categories, and updated release packages)

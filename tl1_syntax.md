# TL1 Command Syntax Reference

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

## Response Format

### Successful Response
```
   {TID} {YYYY-MM-DD} {HH:MM:SS}
M  {CTAG} COMPLD
   "{response data}"
;
```

### Error Response
```
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
```

## Best Practices

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

# 1603_SM vs 1603_SMX Command Reference

## Quick Reference for GitHub Copilot

This directory contains command definitions for two network device systems that share similar functionality but have key differences.

### Systems Overview

| System | Total Commands | Unique Commands | Description |
|--------|----------------|-----------------|-------------|
| **1603_SM** | 564 | 21 | Base system with IPAREA support and extended VPL operations |
| **1603_SMX** | 609 | 69 | Extended system with STS12C, POSPORT, and BLSR support |
| **Common** | 540 | - | Commands available in both systems |

---

## Files in This Directory

### 1. `1603_commands.json`
Complete structured data of all commands and device support.

**Use this for:**
- Data-driven applications
- Command validation
- Building command parsers
- API integrations

### 2. `1603_commands.ts`
TypeScript/JavaScript constants and type definitions.

**Use this for:**
- TypeScript projects
- Frontend applications
- Type-safe command validation
- React/Vue/Angular apps

**Example Usage:**
```typescript
import { isCommandSupported, SystemType, COMMANDS_ONLY_IN_1603_SMX } from './1603_commands';

// Check if a command is supported
if (isCommandSupported('RTRV-STS12C', SystemType.SMX_1603)) {
  console.log('Command supported in 1603_SMX');
}

// Get all SMX-exclusive commands
const smxCommands = COMMANDS_ONLY_IN_1603_SMX;
```

### 3. `commands_1603.py`
Python module with constants and helper functions.

**Use this for:**
- Network automation scripts
- Python-based CLI tools
- Backend services
- Data analysis

**Example Usage:**
```python
from commands_1603 import is_command_supported, SystemType, COMMANDS_ONLY_IN_1603_SMX

# Check if a command is supported
if is_command_supported('RTRV-STS12C', SystemType.SMX_1603):
    print('Command supported in 1603_SMX')

# Get device from command
device = get_device_from_command('RTRV-STS12C')  # Returns 'STS12C'
```

---

## Key Differences at a Glance

### 🆕 New in 1603_SMX (Not in 1603_SM)

#### Major Features
- **STS12C** (26 commands) - High-speed concatenated transport
  - Full provisioning: ENT-STS12C, ED-STS12C, DLT-STS12C
  - Cross-connects: ENT-CRS-STS12C, ED-CRS-STS12C, DLT-CRS-STS12C
  - Performance monitoring: RTRV-PM-STS12C, SET-PMMODE-STS12C
  - Protection switching: OPR-PROTNSW-STS12C, RLS-PROTNSW-STS12C

- **POSPORT** (14 commands) - Packet over SONET/SDH
  - Full CRUD: ED-POSPORT, RTRV-POSPORT
  - Alarms: RTRV-ALM-POSPORT
  - Performance: RTRV-PM-POSPORT, SET-PMMODE-POSPORT
  - Thresholds: RTRV-TH-POSPORT, SET-TH-POSPORT

- **BLSR** (6 commands) - Bidirectional Line Switched Ring
  - Monitoring: RTRV-ALM-BLSR, RTRV-ATTR-BLSR, RTRV-COND-BLSR
  - Configuration: SET-ATTR-BLSR, SET-NE-BLSR, RTRV-NE-BLSR

- **RINGMAP & SQLMAP** (6 commands) - Enhanced mapping
  - Ring mapping: ENT-RINGMAP, DLT-RINGMAP, RTRV-RINGMAP
  - SQL mapping: ENT-SQLMAP, DLT-SQLMAP, RTRV-SQLMAP

#### Enhanced Features
- **OC48**: Added 7 commands including FFP, protection switching
- **IPT**: Added 4 alarm and attribute commands
- **Thresholds**: SET-TH commands for AAL5, ATMPORT, ATMPROC

### 🔵 Exclusive to 1603_SM (Not in 1603_SMX)

- **IPAREA** (4 commands) - IP Area management
  - ENT-IPAREA, ED-IPAREA, DLT-IPAREA, RTRV-IPAREA

- **VPL Extended** (11 commands) - More VPL operations
  - Cross-connects: ENT-CRS-VPL, ED-CRS-VPL, DLT-CRS-VPL, RTRV-CRS-VPL
  - FFP: ED-FFP-VPL, RTRV-FFP-VPL
  - Full CRUD: ENT-VPL, DLT-VPL
  - Protection: OPR-PROTNSW-VPL, RLS-PROTNSW-VPL

- **ATMPORT Logging** (2 commands)
  - INIT-LOLOG-ATMPORT, RTRV-LOLOG-ATMPORT

---

## Command Naming Convention

All commands follow this pattern: `{OPERATION}-{QUALIFIER?}-{DEVICE}`

### Operation Prefixes
- **RTRV** - Retrieve (read data)
- **ENT** - Enter (create new)
- **ED** - Edit (modify existing)
- **DLT** - Delete (remove)
- **SET** - Set (configure parameters)
- **OPR** - Operate (perform action)
- **RLS** - Release (free resource)
- **INH** - Inhibit (disable feature)
- **ALW** - Allow (enable feature)
- **INIT** - Initialize (start up)
- **DGN** - Diagnose (test)

### Common Qualifiers
- **ALM** - Alarms
- **ATTR** - Attributes
- **COND** - Conditions
- **CRS** - Cross-connect
- **FFP** - Facility Protection Path
- **PM** - Performance Monitoring
- **PMMODE** - Performance Monitoring Mode
- **PMREPT** - Performance Monitoring Report
- **PROTNSW** - Protection Switch
- **TH** - Threshold

### Examples
- `RTRV-ALM-STS12C` - Retrieve alarms for STS12C device
- `ENT-CRS-VPL` - Enter (create) a cross-connect for VPL
- `SET-TH-POSPORT` - Set thresholds for POSPORT

---

## Copilot Tips

### For Command Validation
```typescript
// Copilot will suggest correct system checks
function validateCommand(cmd: string, system: SystemType) {
  return isCommandSupported(cmd, system);
}
```

### For Building CLI Tools
```python
# Copilot will understand device types
def execute_command(command: str, system: SystemType):
    if not is_command_supported(command, system):
        raise ValueError(f"{command} not supported in {system.value}")
    
    device = get_device_from_command(command)
    # ... execute command
```

### For Filtering Commands
```typescript
// Copilot will suggest SMX-specific features
function getSMXEnhancements() {
  return COMMANDS_ONLY_IN_1603_SMX.filter(cmd => 
    cmd.includes('STS12C') || cmd.includes('POSPORT')
  );
}
```

---

## Device Support Matrix

| Device | 1603_SM | 1603_SMX | Notes |
|--------|---------|----------|-------|
| STS12C | ❌ | ✅ | SMX only - 26 commands |
| POSPORT | ❌ | ✅ | SMX only - 14 commands |
| BLSR | ❌ | ✅ | SMX only - 6 commands |
| RINGMAP | ❌ | ✅ | SMX only - 3 commands |
| SQLMAP | ❌ | ✅ | SMX only - 3 commands |
| IPAREA | ✅ | ❌ | SM only - 4 commands |
| VPL | ✅ (33) | ✅ (23) | SM has 11 additional commands |
| OC48 | ✅ (22) | ✅ (29) | SMX has 7 additional commands |
| IPT | ✅ (4) | ✅ (8) | SMX has 4 additional commands |
| All Others | ✅ | ✅ | Same or similar support |

✅ = Supported | ❌ = Not supported

---

## GitHub Copilot Context

When GitHub Copilot sees these files in your project, it will understand:

1. **System Differences**: Which commands are available in each system
2. **Device Types**: What devices are supported and their capabilities  
3. **Command Structure**: How commands are named and organized
4. **Validation Logic**: How to check command compatibility
5. **Type Safety**: Proper TypeScript/Python types for commands

### Prompting Copilot

Good prompts to use with these files:

- "Create a function to validate 1603_SMX commands"
- "Generate a CLI tool that checks if a command is supported in 1603_SM"
- "Build a command parser that handles both systems"
- "Create a React component that filters commands by device type"
- "Write tests for command validation between systems"

---

## Quick Stats

- **Total unique commands across both systems**: 630
- **Common commands**: 540 (85.7%)
- **System-specific commands**: 90 (14.3%)
- **Devices supported**: 76 device types
- **New devices in SMX**: 5 (STS12C, POSPORT, BLSR, RINGMAP, SQLMAP)
- **SM-exclusive devices**: 1 (IPAREA)

---

## License & Usage

These command definitions are for development reference. Use them to:
- Build network management applications
- Create command validation tools
- Develop automated testing frameworks
- Generate documentation
- Train AI assistants on command structures

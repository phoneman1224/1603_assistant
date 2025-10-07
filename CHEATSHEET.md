# 1603_SM vs 1603_SMX Quick Reference Cheat Sheet

## System Selection Guide

```
Use 1603_SM when you need:
- IPAREA management (4 commands)
- Extended VPL cross-connects and FFP (11 additional commands)
- ATMPORT logging (LOLOG) functionality

Use 1603_SMX when you need:
- STS12C high-speed transport (26 commands)
- POSPORT packet transport (14 commands)
- BLSR ring topology (6 commands)
- RINGMAP/SQLMAP (6 commands)
- Enhanced OC48 features (7 additional commands)
- Enhanced threshold setting (SET-TH-*)
```

---

## Commands NOT Available in 1603_SMX (Use 1603_SM)

```
IP Management:
├── DLT-IP
├── ED-IP
└── ENT-IP

IPAREA Management:
├── DLT-IPAREA
├── ED-IPAREA
├── ENT-IPAREA
└── RTRV-IPAREA

VPL Cross-Connects:
├── DLT-CRS-VPL
├── ED-CRS-VPL
├── ENT-CRS-VPL
└── RTRV-CRS-VPL

VPL FFP:
├── ED-FFP-VPL
└── RTRV-FFP-VPL

VPL Provisioning:
├── DLT-VPL
└── ENT-VPL

VPL Operations:
├── INH-PMREPT-VPL
├── OPR-PROTNSW-VPL
└── RLS-PROTNSW-VPL

ATMPORT Logging:
├── INIT-LOLOG-ATMPORT
└── RTRV-LOLOG-ATMPORT

SYNCN:
└── SET-PMMODE-SYNCN
```

---

## Commands NOT Available in 1603_SM (Use 1603_SMX)

```
STS12C (26 commands):
├── Provisioning: ENT/ED/DLT-STS12C
├── Cross-Connects: ENT/ED/DLT-CRS-STS12C, RTRV-CRS-STS12C
├── Alarms: RTRV-ALM-STS12C
├── Attributes: RTRV-ATTR-STS12C, SET-ATTR-STS12C
├── Conditions: RTRV-COND-STS12C
├── Diagnostics: DGN-STS12C
├── FFP: ED-FFP-STS12C, RTRV-FFP-STS12C
├── Performance: RTRV-PM-STS12C, RTRV-PMMODE-STS12C, SET-PMMODE-STS12C
├── PM Reports: ALW-PMREPT-STS12C, INH-PMREPT-STS12C
├── Protection: OPR-PROTNSW-STS12C, RLS-PROTNSW-STS12C
├── Registration: INIT-REG-STS12C
├── Thresholds: RTRV-TH-STS12C, SET-TH-STS12C
└── Path Trace: RTRV-PTHTRC-STS12C

POSPORT (14 commands):
├── Provisioning: ED-POSPORT, RTRV-POSPORT
├── Alarms: RTRV-ALM-POSPORT
├── Attributes: RTRV-ATTR-POSPORT, SET-ATTR-POSPORT
├── Conditions: RTRV-COND-POSPORT
├── Performance: RTRV-PM-POSPORT, RTRV-PMMODE-POSPORT, SET-PMMODE-POSPORT
├── PM Reports: ALW-PMREPT-POSPORT, INH-PMREPT-POSPORT
├── Registration: INIT-REG-POSPORT
└── Thresholds: RTRV-TH-POSPORT, SET-TH-POSPORT

BLSR (6 commands):
├── Alarms: RTRV-ALM-BLSR
├── Attributes: RTRV-ATTR-BLSR, SET-ATTR-BLSR
├── Conditions: RTRV-COND-BLSR
└── Network Elements: RTRV-NE-BLSR, SET-NE-BLSR

OC48 Enhanced (7 additional commands):
├── ALW-EX-OC48
├── ED-FFP-OC48
├── EX-SW-OC48
├── INH-EX-OC48
├── OPR-PROTNSW-OC48
├── RLS-PROTNSW-OC48
└── RTRV-FFP-OC48

IPT Enhanced (4 additional commands):
├── RTRV-ALM-IPT
├── RTRV-ATTR-IPT
├── RTRV-COND-IPT
└── SET-ATTR-IPT

Mapping Functions:
├── RINGMAP: DLT/ENT/RTRV-RINGMAP
└── SQLMAP: DLT/ENT/RTRV-SQLMAP

Threshold Setting (Enhanced):
├── SET-TH-AAL5
├── SET-TH-ATMPORT
└── SET-TH-ATMPROC

IP & Other:
├── SET-IP
├── IINH-PMREPT-VPL
└── SET-PMMMODE-SYNCN
```

---

## Validation Code Snippets

### TypeScript
```typescript
import { isCommandSupported, SystemType } from './1603_commands';

// Check command support
const cmd = 'RTRV-STS12C';
const supportedInSM = isCommandSupported(cmd, SystemType.SM_1603);   // false
const supportedInSMX = isCommandSupported(cmd, SystemType.SMX_1603); // true

// Validate before execution
function executeCommand(cmd: string, system: SystemType) {
  if (!isCommandSupported(cmd, system)) {
    throw new Error(`${cmd} not supported in ${system}`);
  }
  // ... execute
}
```

### Python
```python
from commands_1603 import is_command_supported, SystemType

# Check command support
cmd = 'RTRV-STS12C'
supported_in_sm = is_command_supported(cmd, SystemType.SM_1603)   # False
supported_in_smx = is_command_supported(cmd, SystemType.SMX_1603) # True

# Validate before execution
def execute_command(cmd: str, system: SystemType):
    if not is_command_supported(cmd, system):
        raise ValueError(f"{cmd} not supported in {system.value}")
    # ... execute
```

---

## Device Support Quick Check

| Device | SM | SMX | Notes |
|--------|-----|-----|-------|
| STS12C | ❌ | ✅ | SMX exclusive |
| POSPORT | ❌ | ✅ | SMX exclusive |
| BLSR | ❌ | ✅ | SMX exclusive |
| RINGMAP | ❌ | ✅ | SMX exclusive |
| SQLMAP | ❌ | ✅ | SMX exclusive |
| IPAREA | ✅ | ❌ | SM exclusive |
| VPL | ✅++ | ✅ | SM has more commands |
| OC48 | ✅ | ✅+ | SMX has more commands |
| IPT | ✅ | ✅+ | SMX has more commands |
| Others | ✅ | ✅ | Generally equal |

---

## Command Pattern Matching

```regex
# Commands for STS12C (SMX only)
^(ALW|DGN|DLT|ED|ENT|INH|INIT|OPR|RLS|RTRV|SET)-.*-STS12C$

# Commands for POSPORT (SMX only)
^(ALW|ED|INH|INIT|RTRV|SET)-.*-POSPORT$

# Commands for BLSR (SMX only)
^(RTRV|SET)-.*-BLSR$

# Commands for IPAREA (SM only)
^(DLT|ED|ENT|RTRV)-IPAREA$

# VPL cross-connect commands (SM only)
^(DLT|ED|ENT|RTRV)-CRS-VPL$
```

---

## Migration Checklist (SM → SMX)

### ✅ Compatible (Safe to migrate)
- All common commands (540 commands)
- AAL5, ATMPROC, EC1, EQPT, T1, T3 operations
- OC12, OC3 operations
- Most VPL operations (basic provisioning)

### ⚠️ Need Alternatives (Incompatible)
```
SM Command           → SMX Alternative
────────────────────────────────────────
DLT-IP              → Use SET-IP
ED-IP               → Use SET-IP
ENT-IP              → Use SET-IP
DLT-IPAREA          → (No direct alternative)
ED-IPAREA           → (No direct alternative)
ENT-IPAREA          → (No direct alternative)
RTRV-IPAREA         → (No direct alternative)
*-CRS-VPL           → (VPL cross-connects not available)
*-FFP-VPL           → (VPL FFP not available)
INH-PMREPT-VPL      → Use IINH-PMREPT-VPL
SET-PMMODE-SYNCN    → Use SET-PMMMODE-SYNCN (note typo)
```

### ✨ New Capabilities in SMX
- STS12C high-speed transport
- POSPORT packet capabilities
- BLSR ring topology support
- Enhanced OC48 protection
- Comprehensive threshold setting

---

## Common Mistakes to Avoid

```
❌ Don't use RTRV-STS12C on 1603_SM (not supported)
✅ Use RTRV-STS3C or RTRV-STS1 instead

❌ Don't use DLT-IPAREA on 1603_SMX (not supported)
✅ Check if IPAREA is required, or use 1603_SM

❌ Don't assume VPL cross-connects work on both
✅ VPL cross-connects only in 1603_SM

❌ Don't use SET-TH-AAL5 on 1603_SM (not supported)
✅ Use regular threshold commands or upgrade to SMX
```

---

## Stats at a Glance

```
Total Commands:          630 (combined unique)
Common Commands:         540 (85.7%)
1603_SM Unique:          21  (3.3%)
1603_SMX Unique:         69  (11.0%)
Compatibility:           ~96% (SM commands work in SMX)
```

---

## When to Use Which System

```
Choose 1603_SM if:
✓ You need IPAREA management
✓ You need VPL cross-connects or FFP
✓ You need ATMPORT logging
✓ You're maintaining legacy infrastructure

Choose 1603_SMX if:
✓ You need STS12C capabilities
✓ You need packet-over-SONET (POSPORT)
✓ You need BLSR ring topology
✓ You need enhanced OC48 features
✓ You want the latest feature set
✓ You're building new infrastructure
```

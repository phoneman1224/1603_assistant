# TL1 Assistant - Web-based TL1 Command Interface

A simple, web-based TL1 (Transaction Language 1) command interface for network device management. No installation or admin rights required - runs entirely from a web browser.

## Features

- **Web-based interface** - No software installation required
- **Direct Telnet communication** - Connect directly to TL1 devices
- **630 pre-loaded commands** - Comprehensive command database
- **Platform support** - 1603 SM and 1603 SMX systems
- **Cross-platform** - Works on Windows, Linux, and Mac
- **No admin rights** - Run without elevated permissions

## Quick Start

### Windows
```cmd
Start-WebGUI.cmd
```

### Linux/Mac
```bash
./start-webgui.sh
```

### Manual Start
```bash
python3 tl1_web_gui.py
```

The web interface will open automatically at `http://localhost:8081`

## Requirements

- Python 3.6 or later
- Flask (will be installed automatically)

## Installation

1. Clone or download this repository
2. Run the startup script for your platform
3. That's it! The web GUI will open in your browser

## Usage

1. **Start the application** using one of the startup scripts
2. **Connect to device** by entering the IP address and port (default: 23)
3. **Select commands** from the dropdown (filtered by platform)
4. **Send commands** to your TL1 device
5. **View responses** in the output area

## Repository Structure

```
/
├── tl1_web_gui.py          # Main web application
├── data/
│   └── commands.json       # TL1 commands database (630 commands)
├── requirements.txt        # Python dependencies
├── Start-WebGUI.cmd       # Windows startup script
├── start-webgui.sh        # Linux/Mac startup script
└── README.md              # This file
```

## Command Database

The application includes 630 TL1 commands:
- **561 commands** for 1603 SM platform
- **609 commands** for 1603 SMX platform
- **540 commands** common to both platforms

Commands are automatically filtered based on the selected platform.

## Platform Differences

| Platform | Features |
|----------|----------|
| **1603 SM** | Base system with IPAREA support and extended VPL operations |
| **1603 SMX** | Extended system with STS12C, POSPORT, and BLSR support |

## Development

The application is built with:
- **Backend**: Python Flask with Telnet communication
- **Frontend**: HTML5, CSS3, JavaScript (embedded in the Python file)
- **Database**: JSON file with structured command data

## Troubleshooting

### Connection Issues
- Ensure the device IP and port are correct
- Check network connectivity to the device
- Verify the device supports Telnet on the specified port

### Python Issues
- Make sure Python 3.6+ is installed
- Install Flask if missing: `pip install flask`

### Port Conflicts
- If port 8081 is in use, modify the port in `tl1_web_gui.py`

## License

This project is provided as-is for network device management purposes.
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

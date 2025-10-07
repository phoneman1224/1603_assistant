# TL1 Assistant - Directory Structure

This document describes the complete directory structure and file organization of the TL1 Assistant project.

## Root Directory Structure

```
1603_assistant/
├── README.md                    # Main project documentation
├── requirements.txt             # Python dependencies
├── tl1_web_gui.py              # Main web application
├── Start-WebGUI.cmd            # Windows startup script
├── start-webgui.sh             # Linux/Mac startup script
├── command_examples.json       # TL1 command examples and patterns
├── copilot_prompt.txt          # GitHub Copilot system prompt
├── directory_structure.md      # This file
├── quick_start.md              # Quick start guide
├── tl1_syntax.md               # TL1 command syntax reference
├── tap-001.md                  # Troubleshooting procedures
└── data/                       # Data directory
    └── commands.json           # Complete TL1 command database
```

## File Descriptions

### Core Application Files

| File | Purpose | Size | Dependencies |
|------|---------|------|--------------|
| `tl1_web_gui.py` | Main web application with Flask server and embedded HTML/CSS/JS | ~31KB | Flask, telnetlib |
| `data/commands.json` | Complete database of 630 TL1 commands with metadata | ~685KB | None |
| `requirements.txt` | Python package dependencies | ~13B | None |

### Startup Scripts

| File | Platform | Purpose |
|------|----------|---------|
| `Start-WebGUI.cmd` | Windows | Batch script with Python version checking and dependency installation |
| `start-webgui.sh` | Linux/Mac | Bash script with Python version checking and dependency installation |

### Documentation Files

| File | Purpose | Target Audience |
|------|---------|-----------------|
| `README.md` | Main project documentation and usage instructions | End users, developers |
| `quick_start.md` | Rapid deployment guide | New users |
| `tl1_syntax.md` | TL1 command syntax and structure reference | TL1 operators |
| `tap-001.md` | Troubleshooting and problem resolution procedures | Technical support |
| `command_examples.json` | JSON database of common command examples | Developers, operators |
| `copilot_prompt.txt` | AI assistant system prompt for TL1 expertise | AI/Copilot integration |
| `directory_structure.md` | This file - project organization | Developers, maintainers |

## Data Structure

### commands.json Structure
```json
{
  "metadata": {
    "version": "6.0",
    "totalCommands": 630,
    "platforms": ["1603 SM", "1603 SMX"]
  },
  "categories": {
    "category_name": {
      "description": "Category description",
      "icon": "icon_name"
    }
  },
  "commands": {
    "COMMAND-ID": {
      "id": "COMMAND-ID",
      "displayName": "Human readable name",
      "platforms": ["1603 SM", "1603 SMX"],
      "category": "Category name",
      "description": "Command description",
      "syntax": "TL1 syntax pattern",
      "requires": ["TID", "CTAG"],
      "optional": ["AID"],
      "paramSchema": {
        "TID": {
          "type": "string",
          "maxLength": 20,
          "description": "Target identifier"
        }
      },
      "examples": ["Example command"],
      "safety_level": "safe|dangerous",
      "service_affecting": true|false
    }
  }
}
```

## Web Application Architecture

### Python Backend (tl1_web_gui.py)
- **TL1Backend Class**: Handles Telnet communication with network elements
- **TL1WebHandler Class**: HTTP request handler for web interface
- **Flask Integration**: Serves web interface and API endpoints
- **Command Processing**: Filters and validates TL1 commands

### Frontend (Embedded in tl1_web_gui.py)
- **HTML Structure**: Single-page application layout
- **CSS Styling**: Responsive design with modern UI components
- **JavaScript Logic**: Dynamic command building and real-time preview
- **API Integration**: RESTful communication with Python backend

### API Endpoints
- `GET /` - Main web interface
- `GET /api/commands` - Command list with platform filtering
- `POST /api/connect` - Establish Telnet connection
- `POST /api/disconnect` - Close Telnet connection
- `POST /api/send_command` - Execute TL1 command
- `GET /api/status` - Connection status

## Platform Support

### 1603 SM (561 Commands)
- Base system functionality
- IPAREA support
- Extended VPL operations
- Standard OC12/OC48 interfaces

### 1603 SMX (609 Commands)
- All 1603 SM functionality
- Additional STS12C support (26 commands)
- POSPORT interfaces (14 commands)
- BLSR protection (6 commands)

### Common Commands (540)
- Shared between both platforms
- Core system management
- Standard monitoring and configuration
- Basic maintenance operations

## Development Environment

### Required Tools
- Python 3.6+ 
- Git for version control
- Text editor (VS Code recommended)
- Web browser for testing

### Optional Tools
- PyInstaller (for standalone executables)
- Docker (for containerized deployment)
- systemd (for Linux service deployment)

## Deployment Models

### Development
- Direct Python execution: `python3 tl1_web_gui.py`
- Automatic browser opening
- Hot reload for development changes

### Production
- Service deployment with systemd/Windows Service
- Reverse proxy with nginx/Apache
- SSL/TLS termination
- Process monitoring and logging

### Portable
- PyInstaller standalone executable
- USB drive deployment
- No installation required
- Self-contained dependencies

## File Size Analysis

| Category | Files | Total Size | Percentage |
|----------|-------|------------|------------|
| Core Application | 3 files | ~716KB | 85% |
| Documentation | 6 files | ~50KB | 6% |
| Scripts | 2 files | ~1.4KB | <1% |
| Configuration | 2 files | ~400B | <1% |
| **Total** | **13 files** | **~768KB** | **100%** |

The project maintains a minimal footprint while providing comprehensive functionality for TL1 network element management.
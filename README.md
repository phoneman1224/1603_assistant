# TL1 Assistant - Hybrid Web GUI

A complete TL1 command management system with both **Web UI** and **Desktop WPF** interfaces for Alcatel 1603 SM/SMX network equipment.

## Architecture

This is a **hybrid application** that provides:

- **FastAPI Backend**: Python-based REST API with structured logging
- **React Frontend**: Modern web interface with dynamic forms
- **Desktop WPF**: PowerShell-based desktop GUI (optional)
- **Native TCP/Telnet**: Direct device communication without SecureCRT
- **Data-Driven**: JSON-based command catalogs and playbooks

## Quick Start

### Prerequisites

- Python 3.8+ (required)
- Node.js 18+ (required for Web UI)
- PowerShell 5.1+ (required for send script and optional desktop GUI)

### Installation and Launch

**Option 1: Web UI (Recommended)**

```powershell
# Run the bootstrap script - it does everything!
.\scripts\windows_bootstrap.ps1
```

This will:
1. Create Python virtual environment
2. Install all dependencies (Python + Node)
3. Validate data files
4. Start FastAPI backend on http://127.0.0.1:8000
5. Start Vite dev server on http://127.0.0.1:5173
6. Open your browser automatically

**Option 2: Desktop GUI**

```powershell
.\scripts\windows_bootstrap.ps1 -LaunchDesktop
```

**Option 3: Production Build**

```powershell
.\scripts\windows_bootstrap.ps1 -Production
```

This builds a static UI and serves everything from the API server.

## Features

### Web UI Features

- **System Selector**: Choose between 1603 SM and 1603 SMX platforms
- **Category Browser**: Browse commands organized by function
- **Dynamic Forms**: Auto-generated forms based on command schemas
- **Live Preview**: Real-time TL1 command preview with validation
- **Console Output**: Structured logs with [SEND], [RECV], [INFO] levels
- **Command History**: Track all sent commands and responses
- **Troubleshooting Playbooks**: Run automated diagnostic workflows
- **Provisioning Wizard**: Step-by-step circuit provisioning

### Backend API Features

- **RESTful API**: Standard HTTP endpoints for all operations
- **Structured Logging**: Daily log rotation with proper formatting
- **CTAG Management**: Automatic correlation tag incrementing
- **Job Management**: Async command execution with status polling
- **Settings Persistence**: Centralized configuration in settings.json
- **Command Validation**: Lenient validation with warnings

## Files Included

### 📋 Documentation Files (Add to Repository)

1. **tl1_syntax.md** (61 KB)
   - Complete TL1 command syntax reference
   - **CRITICAL vacant parameter rules**
   - Command format and examples
   - Best practices
   - Location: `data/platforms/alcatel_1603/tl1_syntax.md`

2. **command_examples.json** (8 KB)
   - JSON database of TL1 commands
   - Categorized by function
   - Parameter definitions
   - Response codes
   - Location: `data/platforms/alcatel_1603/commands/command_examples.json`

3. **TAP-001.md** (8 KB)
   - Sample troubleshooting procedure
   - Alarm identification guide
   - Step-by-step instructions
   - AI assistant triggers
   - Location: `data/platforms/alcatel_1603/tap_procedures/TAP-001.md`

4. **DIRECTORY_STRUCTURE.md** (5 KB)
   - Recommended file organization
   - Directory layout
   - File descriptions
   - Integration points
   - Location: `data/platforms/alcatel_1603/DIRECTORY_STRUCTURE.md`

### 📝 Instructions

5. **COPILOT_PROMPT.txt** (12 KB)
   - **COPY THIS INTO GITHUB COPILOT CHAT**
   - Complete build instructions
   - Technical specifications
   - All requirements
   - This is what Copilot needs to build your GUI

6. **QUICK_START.md** (6 KB)
   - Step-by-step guide
   - How to add files to repo
   - How to use Copilot
   - Troubleshooting tips
   - Success criteria

## Quick Start

### 1. Add Documentation to Your Repo

```
1603_assistant/
└── data/
    └── platforms/
        └── alcatel_1603/
            ├── tl1_syntax.md              ← Add
            ├── DIRECTORY_STRUCTURE.md     ← Add
            ├── commands/
            │   └── command_examples.json  ← Add
            └── tap_procedures/
                └── TAP-001.md             ← Add
```

### 2. Commit to GitHub

```bash
git add data/platforms/alcatel_1603/
git commit -m "Add documentation for 1603 Assistant"
git push origin main
```

### 3. Tell GitHub Copilot to Build

Open GitHub Copilot Chat and paste the contents of:
**COPILOT_PROMPT.txt**

### 4. Test Your Application

```bash
python launch.py
```

## What Copilot Will Build

✅ **Main GUI Window** with:
- Connection panel (host, port, connect/disconnect)
- TL1 command builder (dropdowns + inputs)
- Response display area
- AI assistant panel

✅ **Proper Vacant Parameter Handling:**
- Empty parameters = `::` (no text)
- Never "null", "empty", or placeholders

✅ **Telnet Connection:**
- Connect to equipment on port 10201
- Send TL1 commands
- Receive and display responses

✅ **AI Assistant:**
- Natural language queries
- TAP/DLP procedure matching
- Command suggestions
- Step-by-step guidance

## Key Features

### Command Builder
- Select verb, modifier, object from dropdowns
- Input TID, AID, CTAG as needed
- Preview command before sending
- **Vacant parameters stay empty!**

### AI Assistant Triggers
- "I see alarms" → Load TAP-001
- "provision T1" → Show provisioning guide
- "OC12 troubleshooting" → Suggest diagnostics
- "equipment failure" → Load equipment TAPs

## Critical Success Criteria

The #1 requirement is **correct vacant parameter handling**:

✅ Correct:
```
RTRV-ALM-ALL:::123::;           # TID and AID vacant
RTRV-ALM-ALL:SITE01::456::;     # AID vacant
```

❌ Wrong:
```
RTRV-ALM-ALL:TID:AID:123::;     # Never!
RTRV-ALM-ALL:null:null:123::;   # Never!
```

## File Sizes

- tl1_syntax.md: ~61 KB
- command_examples.json: ~8 KB  
- TAP-001.md: ~8 KB
- DIRECTORY_STRUCTURE.md: ~5 KB
- COPILOT_PROMPT.txt: ~12 KB
- QUICK_START.md: ~6 KB
- **Total: ~100 KB**

## Next Steps

1. ✅ Download all files
2. ✅ Add to your repository structure
3. ✅ Commit and push to GitHub
4. ✅ Open Copilot Chat
5. ✅ Paste COPILOT_PROMPT.txt
6. ✅ Let Copilot build the GUI
7. ✅ Test and refine

## Questions?

If Copilot doesn't build correctly:
- Make sure files are committed to the repo
- Reference specific files in your prompts
- Point out the vacant parameter rules explicitly
- Ask Copilot to "read tl1_syntax.md"

## API Endpoints

The FastAPI backend provides the following endpoints:

### Health & Status
- `GET /api/health` - Health check with version info

### Commands
- `GET /api/commands` - List all commands (filter by `?platform=`)
- `GET /api/commands/categories` - List categories with counts
- `GET /api/commands/{id}` - Get specific command details
- `POST /api/commands/preview` - Build and preview command
- `POST /api/commands/reload` - Reload command catalog

### Settings
- `GET /api/settings` - Get current settings
- `PUT /api/settings` - Update settings
- `POST /api/settings/ctag/increment` - Increment CTAG counter

### Send Commands
- `POST /api/send` - Send TL1 command (returns job ID)
- `GET /api/send/jobs/{id}` - Get job status and output
- `DELETE /api/send/jobs/{id}` - Delete completed job

### Playbooks
- `GET /api/playbooks` - List all troubleshooting & provisioning playbooks
- `GET /api/playbooks/{flowName}` - Get specific playbook
- `POST /api/playbooks/troubleshoot` - Run troubleshooting playbook
- `POST /api/playbooks/provision` - Run provisioning workflow

## Project Structure

```
1603_assistant/
├── data/                    # Data files
│   ├── commands.json        # TL1 command catalog (630 commands)
│   └── playbooks.json       # Troubleshooting & provisioning flows
├── logs/                    # Structured logs (YYYY-MM/tl1_YYYY-MM-DD.log)
├── powershell/              # PowerShell scripts
│   ├── send_tl1.ps1        # Native TCP sender (authoritative)
│   └── TL1_CommandBuilder.ps1  # Desktop WPF GUI
├── scripts/                 # Build & launch scripts
│   ├── windows_bootstrap.ps1   # Complete setup & launch
│   ├── serve_web.ps1           # Run API + UI concurrently
│   ├── validate_data.py        # JSON schema validation
│   └── build_database.ps1      # Deterministic DB build
├── src/webapi/              # FastAPI backend
│   ├── app.py              # Main FastAPI application
│   ├── logging_conf.py     # Structured logging setup
│   ├── models/             # Pydantic schemas
│   ├── routers/            # API route handlers
│   └── services/           # Business logic (catalog, builder, runner)
├── webui/                   # React frontend
│   ├── src/
│   │   ├── api/            # API client layer
│   │   ├── components/     # React components
│   │   ├── state/          # Zustand state management
│   │   └── App.tsx         # Main app component
│   ├── package.json        # Node dependencies
│   └── vite.config.ts      # Vite configuration
├── settings.json            # Unified settings (shared by desktop & web)
└── requirements.txt         # Python dependencies
```

## Development

### Run Tests

```powershell
# Validate data files
python scripts/validate_data.py

# Run API tests
pytest

# Type-check UI
cd webui
npm run build
```

### CI/CD

GitHub Actions workflow (`.github/workflows/web-ci.yml`) runs on every push:
- Validates JSON data schemas
- Tests API imports
- Builds and type-checks React UI

## Documentation

- **tl1_syntax.md** - Complete TL1 command syntax reference
- **TAP-001.md** - Sample troubleshooting procedure
- **command_examples.json** - Legacy command examples

## License

Internal tool for network equipment management.

## Support

For issues or questions, please open a GitHub issue.

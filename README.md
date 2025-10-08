# 1603 Assistant - Hybrid Platform

A comprehensive TL1 command man## 📁 Repository Structure

```
.
├── CLICK_TO_START.cmd       # 🎯 MAIN LAUNCHER - Double-click to start!
├── START_HERE.ps1           # PowerShell launcher (same functionality)
├── QUICK_START.md           # Simple getting started guide
├── README.md                # This comprehensive documentation
├── requirements.txt         # Python dependencies
├── settings.json            # Application configuration
├── data/                    # Command catalogs and playbooks
│   ├── commands.json        # 630+ TL1 commands database  
│   └── playbooks.json       # Automated workflows
├── webui/                   # Modern React frontend
│   ├── src/components/      # UI components
│   ├── src/api/            # API client
│   └── package.json        # Node dependencies
├── src/webapi/             # FastAPI backend
│   ├── app.py              # Main API server
│   ├── routers/            # API endpoints
│   └── services/           # Business logic
├── powershell/             # Desktop GUI components
│   ├── TL1_CommandBuilder.ps1  # Legacy WPF interface
│   └── send_tl1.ps1           # Network communication
├── scripts/                # Utility and automation scripts
│   ├── serve_web.ps1         # Development server
│   ├── cleanup.sh            # Maintenance
│   └── validate_data.py      # Data validation
└── docs/                   # Project documentation
    └── tl1_syntax.md       # TL1 command reference
```Alcatel 1603 SM/SMX network equipment with both **Web UI** and **Desktop** interfaces.

## Architecture

This hybrid application provides:

- **FastAPI Backend**: Python-based REST API with structured logging
- **React Frontend**: Modern web interface with dynamic forms
- **Desktop GUI**: PowerShell-based WPF interface (legacy support)
- **Native TCP/Telnet**: Direct device communication
- **Data-Driven**: JSON-based command catalogs and documentation
- **Platform Documentation**: Comprehensive PDF management and indexing

## Quick Start

### 🚀 **ONE-CLICK START (Windows Users)**

**Simply double-click:** `CLICK_TO_START.cmd`

This single file will:
1. Install Python virtual environment  
2. Install all dependencies (Python + Node.js packages)
3. Validate data files and documentation
4. Start FastAPI backend on http://127.0.0.1:8000
5. Start React frontend on http://127.0.0.1:5173  
6. Open your browser automatically

**That's it!** No technical knowledge required.

### Alternative Methods

**PowerShell Users:**
```powershell
.\START_HERE.ps1
```

**Advanced Options:**
```powershell
.\START_HERE.ps1 -LaunchDesktop    # For legacy PowerShell GUI
.\START_HERE.ps1 -Production       # For production build
```

## 🎯 **For End Users (Network Engineers)**

### Step 1: Get the Application
1. Download or clone this repository to your Windows computer
2. Extract to a folder like `C:\TL1_Assistant\`

### Step 2: One-Click Launch  
**Simply double-click:** `CLICK_TO_START.cmd`

The application will:
- ✅ Install Python virtual environment automatically
- ✅ Download all required dependencies  
- ✅ Validate command database
- ✅ Start web servers
- ✅ Open your browser to the application

### Step 3: Connect to Your Equipment
1. **Enter device IP** and port in the web interface
2. **Select platform**: 1603 SM or 1603 SMX
3. **Browse commands** by category
4. **Fill in parameters** using the dynamic forms
5. **Preview and send** TL1 commands

### Step 4: Use Advanced Features
- **Command History**: Review all sent commands
- **Troubleshooting Playbooks**: Run diagnostic workflows
- **Provisioning Wizards**: Step-by-step circuit setup
- **Documentation Browser**: Access comprehensive guides

---

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
>>>>>>> copilot/update-web-gui-functionality

## � Repository Structure

```
.
├── src/                     # Core Python source code
│   ├── webapi/             # FastAPI backend
│   ├── core/               # Core functionality
│   └── parsers/            # Document parsers
├── data/                   # Platform documentation and schemas
│   ├── platforms/          # Platform-specific files
│   └── shared/             # Shared resources
├── webui/                  # React frontend
│   ├── src/               # React components and logic
│   └── package.json       # Node dependencies
├── docs/                   # Project documentation
├── scripts/                # Utility and automation scripts
├── tests/                  # Test cases and vectors
└── powershell/             # Windows PowerShell GUI components
```

## 🛠️ Setup and Configuration

### Web Interface Features

- **System Selector**: Choose between 1603 SM and 1603 SMX platforms
- **Category Browser**: Browse commands organized by function
- **Dynamic Forms**: Auto-generated forms based on command schemas
- **Live Preview**: Real-time TL1 command preview with validation
- **Console Output**: Structured logs with [SEND], [RECV], [INFO] levels
- **Command History**: Track all sent commands and responses
- **Troubleshooting Playbooks**: Run automated diagnostic workflows
- **Provisioning Wizard**: Step-by-step circuit provisioning

### Platform Documentation

- Documentation is organized under `data/platforms/{platform_id}/`
- Each platform follows a standard structure for commands and docs
- Use `scripts/update_indices.py` to maintain documentation indices
- PDF parsing and structured data extraction

### Development Environment

- Python 3.8+ required for backend and core functionality
- Node.js 18+ required for web interface
- PowerShell 5.1+ required for desktop GUI and scripts
- Additional dependencies listed in `requirements.txt`

### Automation Tools

- Documentation sync: `scripts/sync_google_drive.sh`
- Repository cleanup: `scripts/cleanup.sh`
- Scheduled maintenance: `scripts/setup_scheduled_cleanup.sh`
- Data validation: `scripts/validate_data.py`

## � API Endpoints

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

## 🔄 Maintenance

### Automated Cleanup
- Weekly cleanup runs every Sunday at 2 AM
- Manual cleanup: `./scripts/cleanup.sh`
- Schedule configuration in `.github/workflows/scheduled-cleanup.yml`

### Documentation Updates
1. Sync from source: `./scripts/sync_google_drive.sh`
2. Organize files: `python scripts/organize_files.py`
3. Update indices: `python scripts/update_indices.py`

## 🧪 Testing

1. Run test vectors:
   ```bash
   python -m pytest tests/
   ```
2. Validate data files:
   ```bash
   python scripts/validate_data.py
   ```
3. Check test coverage reports in `tests/coverage/`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and validation
5. Submit a pull request

## 📄 License

This project is proprietary and confidential.

## 🔍 Additional Resources

- Command reference: `data/platforms/{platform_id}/commands/index.json`
- Schema documentation: `data/shared/schemas/`
- API documentation: Auto-generated at `/docs` when running
- TL1 syntax reference: `tl1_syntax.md`
- Troubleshooting guides: `docs/troubleshooting.md`

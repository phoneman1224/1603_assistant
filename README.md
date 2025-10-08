# 1603 Assistant - Hybrid Platform

A comprehensive TL1 command management system for Alcatel 1603 SM/SMX network equipment with both **Web UI** and **Desktop** interfaces.

## Architecture

This hybrid application provides:

- **FastAPI Backend**: Python-based REST API with structured logging
- **React Frontend**: Modern web interface with dynamic forms
- **Desktop GUI**: PowerShell-based WPF interface (legacy support)
- **Native TCP/Telnet**: Direct device communication
- **Data-Driven**: JSON-based command catalogs and documentation
- **Platform Documentation**: Comprehensive PDF management and indexing

## Quick Start

### Prerequisites

- Python 3.8+ (required)
- Node.js 18+ (required for Web UI)
- PowerShell 5.1+ (required for desktop GUI and scripts)

### Installation and Launch

**Option 1: Web UI (Recommended)**

```powershell
# Bootstrap script - installs everything and launches web interface
.\scripts\windows_bootstrap.ps1
```

This will:
1. Create Python virtual environment
2. Install all dependencies (Python + Node)
3. Validate data files and documentation
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

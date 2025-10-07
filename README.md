# 1603 Assistant

A comprehensive tool for managing and interacting with 1603 platform documentation and commands.

## 🚀 Quick Start

### Windows Users
1. Clone this repository
2. Double-click `Start-TL1.cmd` to launch the GUI
3. Enter Host/IP and Port, then click Connect
4. Build and send TL1 commands

### Linux/Unix Users
1. Clone this repository
2. Run the bootstrap script:
   ```bash
   ./scripts/linux_bootstrap.sh
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## 📁 Repository Structure

```
.
├── src/               # Core Python source code
├── data/             # Platform documentation and schemas
│   ├── platforms/    # Platform-specific files
│   └── shared/       # Shared resources
├── docs/             # Project documentation
├── scripts/          # Utility and automation scripts
├── tests/            # Test cases and vectors
└── powershell/       # Windows PowerShell GUI components
```

## 🛠️ Setup and Configuration

1. **Platform Documentation**
   - Documentation is organized under `data/platforms/{platform_id}/`
   - Each platform follows a standard structure for commands and docs
   - Use `scripts/update_indices.py` to maintain documentation indices

2. **Development Environment**
   - Python 3.8+ required for core functionality
   - PowerShell 5.1+ required for Windows GUI
   - Additional dependencies listed in `requirements.txt`

3. **Automation Tools**
   - Documentation sync: `scripts/sync_google_drive.sh`
   - Repository cleanup: `scripts/cleanup.sh`
   - Scheduled maintenance: `scripts/setup_scheduled_cleanup.sh`

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
2. Check test coverage reports in `tests/coverage/`

## 📚 Documentation

- Project overview: `docs/`
- Platform specifics: `data/platforms/README.md`
- API documentation: `docs/api/`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## 📄 License

This project is proprietary and confidential.

## 🔍 Additional Resources

- Command reference: `data/platforms/{platform_id}/commands/index.json`
- Schema documentation: `data/shared/schemas/`
- Troubleshooting guides: `docs/troubleshooting.md`

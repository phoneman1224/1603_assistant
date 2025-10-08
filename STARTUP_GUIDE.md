# TL1 Assistant - Startup Guide

## For Windows Users - One-Click Start

### Quick Start (Recommended)
1. **Double-click `CLICK_TO_START.cmd`**
2. Follow the on-screen prompts
3. The application will automatically start!

### What Happens Automatically
- Creates Python virtual environment if needed
- Installs all required dependencies
- Detects if Node.js is available
- Launches the appropriate interface:
  - **Web Interface** (if Node.js is installed) - Modern browser-based GUI
  - **Desktop Interface** (fallback) - Traditional Python GUI

### Getting the Best Experience
For the modern web interface, install Node.js:
1. Visit [nodejs.org](https://nodejs.org/)
2. Download and install the LTS version
3. Run `CLICK_TO_START.cmd` again

## Alternative Startup Methods

### PowerShell Users
```powershell
# Run the bootstrap script directly
.\START_HERE.ps1
```

### Command Line Users
```batch
# Classic batch approach
.\CLICK_TO_START.cmd
```

## Manual Installation (Advanced Users)

### Prerequisites
- Python 3.8 or higher
- Node.js 16+ (optional, for web interface)

### Setup Steps
```bash
# 1. Create virtual environment
python -m venv venv

# 2. Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 3. Install Python dependencies
pip install -r requirements.txt

# 4. Install Node.js dependencies (optional)
cd webui
npm install
cd ..

# 5. Start the application
python scripts/tl1_web_gui.py
```

## Interfaces Available

### Web Interface (Recommended)
- **URL**: http://localhost:8000
- **Features**: Modern, responsive design with advanced features
- **Requirements**: Node.js must be installed
- **Best for**: Daily use, advanced operations

### Desktop Interface (Fallback)
- **Type**: Python Tkinter GUI
- **Features**: Basic functionality, no browser required
- **Requirements**: Only Python needed
- **Best for**: Systems without Node.js, basic operations

## Troubleshooting

### "Node.js not found" Message
- **Solution**: Install Node.js from [nodejs.org](https://nodejs.org/)
- **Alternative**: Use the desktop interface (automatic fallback)

### Permission Errors on Windows
- **Solution**: Right-click `CLICK_TO_START.cmd` and select "Run as administrator"

### Python Not Found
- **Solution**: Install Python from [python.org](https://python.org/)
- **Note**: Make sure to check "Add Python to PATH" during installation

### Script Won't Run
- **Solution**: Enable script execution in PowerShell:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## File Structure
```
TL1_Assistant/
├── CLICK_TO_START.cmd     # Main Windows launcher
├── START_HERE.ps1         # PowerShell bootstrap script
├── requirements.txt       # Python dependencies
├── data/                  # TL1 commands and playbooks
├── scripts/               # Application scripts
├── src/                   # Python source code
└── webui/                 # Web interface source
```

## Support
If you encounter issues:
1. Check this guide for common solutions
2. Review the console output for error messages
3. Ensure all prerequisites are installed
4. Try the manual installation method

---
*This system automatically adapts to your environment for the best possible experience.*
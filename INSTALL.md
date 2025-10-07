# TL1 Assistant Installation Guide

## 📦 Download and Installation

### Quick Installation

#### Automated Installation (Recommended)
1. **Download** the latest release package:
   - **ZIP**: `TL1Assistant-v1.0.0.zip` (Cross-platform)
   - **TAR.GZ**: `TL1Assistant-v1.0.0.tar.gz` (Linux/macOS)

2. **Extract** the downloaded package to your desired location

3. **Run the installer** for your platform:
   ```bash
   # Linux/macOS
   cd TL1Assistant-v1.0.0
   ./scripts/install.sh
   
   # Windows
   cd TL1Assistant-v1.0.0
   scripts\install.bat
   ```

4. **Launch** TL1 Assistant:
   - Use desktop shortcut (created by installer)
   - Or run: `tl1-assistant` from command line
   - Or manual: `./start-webgui.sh` (Linux/macOS) / `Start-WebGUI.cmd` (Windows)

#### Manual Installation
If you prefer manual setup or the automated installer doesn't work:

1. **Prerequisites**:
   - Python 3.6 or higher
   - pip (Python package manager)

2. **Install dependencies**:
   ```bash
   pip install flask
   ```

3. **Download and extract** TL1 Assistant package

4. **Run directly**:
   ```bash
   # Linux/macOS
   ./start-webgui.sh
   
   # Windows
   Start-WebGUI.cmd
   
   # Or manually
   python3 tl1_web_gui.py
   ```

5. **Access** the web interface at: `http://localhost:8080`

---

## 🔧 System Requirements

### Minimum Requirements
- **Operating System**: Windows 10+, macOS 10.14+, or Linux (Ubuntu 18.04+, CentOS 7+)
- **Python**: Version 3.6 or higher
- **RAM**: 256 MB available memory
- **Storage**: 50 MB free space
- **Network**: Access to target TL1 devices

### Recommended Requirements
- **Operating System**: Latest versions of supported OS
- **Python**: Version 3.8 or higher
- **RAM**: 512 MB available memory
- **Storage**: 100 MB free space (for logs and data)
- **Network**: Gigabit Ethernet for optimal performance
- **Browser**: Chrome 90+, Firefox 85+, Safari 14+, Edge 90+

### Network Requirements
- **Outbound**: TCP port 23 (Telnet) to TL1 devices
- **Inbound**: TCP port 8080 (local web interface)
- **Firewall**: Allow Python/TL1 Assistant through firewall

---

## 📋 Installation Process Details

### Linux Installation Steps

1. **Check Python installation**:
   ```bash
   python3 --version
   # Should show Python 3.6.x or higher
   ```

2. **Install Python if needed**:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install python3 python3-pip
   
   # CentOS/RHEL
   sudo yum install python3 python3-pip
   
   # Or use package manager of your distribution
   ```

3. **Download TL1 Assistant**:
   ```bash
   # Download release package
   wget https://github.com/yourorg/tl1-assistant/releases/download/v1.0.0/TL1Assistant-v1.0.0.tar.gz
   
   # Extract
   tar -xzf TL1Assistant-v1.0.0.tar.gz
   cd TL1Assistant-v1.0.0
   ```

4. **Run installer**:
   ```bash
   chmod +x scripts/install.sh
   ./scripts/install.sh
   ```

5. **Start application**:
   ```bash
   tl1-assistant
   # Or manually: ./start-webgui.sh
   ```

### Windows Installation Steps

1. **Check Python installation**:
   ```cmd
   python --version
   # Should show Python 3.6.x or higher
   ```

2. **Install Python if needed**:
   - Download from [python.org](https://python.org)
   - **IMPORTANT**: Check "Add Python to PATH" during installation
   - Restart command prompt after installation

3. **Download TL1 Assistant**:
   - Download `TL1Assistant-v1.0.0.zip` from releases page
   - Extract to desired location (e.g., `C:\TL1Assistant`)

4. **Run installer**:
   ```cmd
   cd TL1Assistant-v1.0.0
   scripts\install.bat
   ```

5. **Start application**:
   - Use desktop shortcut "TL1 Assistant"
   - Or double-click `Start-WebGUI.cmd`
   - Or from Start Menu: "TL1 Assistant"

### macOS Installation Steps

1. **Check Python installation**:
   ```bash
   python3 --version
   ```

2. **Install Python if needed**:
   ```bash
   # Using Homebrew (recommended)
   brew install python3
   
   # Or download from python.org
   ```

3. **Download and install**:
   ```bash
   # Download release
   curl -L -O https://github.com/yourorg/tl1-assistant/releases/download/v1.0.0/TL1Assistant-v1.0.0.tar.gz
   
   # Extract and install
   tar -xzf TL1Assistant-v1.0.0.tar.gz
   cd TL1Assistant-v1.0.0
   ./scripts/install.sh
   ```

4. **Start application**:
   ```bash
   tl1-assistant
   ```

---

## 🚀 First Run and Configuration

### 1. Initial Launch
After installation, TL1 Assistant will:
- Start a local web server on port 8080
- Automatically open your default browser
- Display the TL1 Assistant interface

### 2. Web Interface Overview
- **Left Sidebar**: Device connection and command selection
- **Right Panel**: Command builder and response area
- **Header**: Version information and status indicators

### 3. Connect to TL1 Device
1. Enter device **IP address** in connection panel
2. Enter **port number** (default: 23)
3. Click **"Connect"** button
4. Wait for connection status to show "Connected"

### 4. Select and Send Commands
1. Choose **platform** (1603 SM or SMX) from dropdown
2. Browse **command tree** in sidebar
3. Click desired command to load in command builder
4. Fill in **required parameters**
5. Review command in **preview area**
6. Click **"Send Command"** button
7. View response in **response area**

---

## 🛠️ Troubleshooting Installation

### Common Issues and Solutions

#### "Python not found" Error
**Symptoms**: Command line shows "python: command not found"
**Solution**:
1. Install Python from [python.org](https://python.org)
2. Ensure Python is added to system PATH
3. Restart terminal/command prompt
4. Try `python3` instead of `python`

#### "Permission denied" Error (Linux/Mac)
**Symptoms**: Cannot execute installation script
**Solution**:
```bash
chmod +x scripts/install.sh
sudo ./scripts/install.sh  # if installation requires admin rights
```

#### "Port 8080 already in use" Error
**Symptoms**: Application fails to start with port error
**Solution**:
1. Find process using port 8080:
   ```bash
   # Linux/Mac
   lsof -i :8080
   
   # Windows
   netstat -ano | findstr :8080
   ```
2. Kill the process or choose different port
3. Modify `tl1_web_gui.py` to use different port if needed

#### "Module not found" Error
**Symptoms**: Python complains about missing Flask module
**Solution**:
```bash
pip install flask
# or
pip3 install flask
# or
python -m pip install flask
```

#### Browser Won't Open Automatically
**Symptoms**: Application starts but browser doesn't open
**Solution**:
1. Manually open browser
2. Navigate to: `http://localhost:8080`
3. Check console output for correct URL
4. Verify firewall isn't blocking connection

### Advanced Troubleshooting

#### Installation in Virtual Environment
For isolated Python environment:
```bash
# Create virtual environment
python3 -m venv tl1-env

# Activate virtual environment
# Linux/Mac:
source tl1-env/bin/activate
# Windows:
tl1-env\Scripts\activate

# Install dependencies
pip install flask

# Run TL1 Assistant
python3 tl1_web_gui.py
```

#### Running on Different Port
To use a different port (e.g., 8081):
1. Edit `tl1_web_gui.py`
2. Find line: `port = find_free_port(8080)`
3. Change to: `port = find_free_port(8081)`
4. Save and restart application

#### Corporate Network Issues
If running in corporate environment:
1. **Proxy Settings**: Configure Python pip for proxy if needed
2. **Firewall**: Request firewall exceptions for ports 23 and 8080
3. **SSL/TLS**: Some corporate networks may interfere with connections
4. **VPN**: Ensure VPN allows access to TL1 devices

---

## 📱 Mobile and Remote Access

### Accessing from Mobile Devices
1. Ensure TL1 Assistant is running on your computer
2. Find your computer's IP address:
   ```bash
   # Linux/Mac
   ip addr show  # or ifconfig
   
   # Windows
   ipconfig
   ```
3. On mobile browser, navigate to: `http://[COMPUTER-IP]:8080`
4. Use responsive mobile interface

### Remote Access Setup
⚠️ **Security Warning**: Only enable remote access on trusted networks

1. **Modify binding** in `tl1_web_gui.py`:
   ```python
   # Change from:
   httpd = HTTPServer(('localhost', port), handler_class)
   # To:
   httpd = HTTPServer(('0.0.0.0', port), handler_class)
   ```

2. **Configure firewall** to allow port 8080

3. **Access remotely**: `http://[SERVER-IP]:8080`

---

## 🔄 Updates and Upgrades

### Checking for Updates
- Version information is displayed in the application header
- Check the GitHub releases page for newer versions
- Compare your version with the latest available

### Upgrade Process
1. **Backup configuration** (if you've made customizations)
2. **Download** new release package
3. **Stop** running TL1 Assistant
4. **Extract** new version over existing installation
5. **Run installer** again to update dependencies
6. **Restart** TL1 Assistant

### Version History
- **v1.0.0**: Initial release with 630+ commands, web interface
- Check GitHub releases for detailed changelogs

---

## 🆘 Getting Help

### Documentation Resources
- **README.md**: Project overview and features
- **quick_start.md**: Rapid deployment guide
- **tap-001.md**: Comprehensive troubleshooting procedures
- **tl1_syntax.md**: Complete TL1 command reference

### Support Channels
1. **Documentation**: Check included documentation files
2. **Troubleshooting**: Use `tap-001.md` for step-by-step problem resolution
3. **GitHub Issues**: Report bugs or request features
4. **Community**: Check discussions and community forums

### Diagnostic Information
When reporting issues, include:
- Operating system and version
- Python version (`python --version`)
- TL1 Assistant version (shown in web interface)
- Exact error messages
- Steps to reproduce the problem

---

**Installation Complete!** 🎉

Your TL1 Assistant is now ready for managing 1603 SM/SMX network elements.
For detailed usage instructions, see `quick_start.md`.
For troubleshooting, refer to `tap-001.md`.
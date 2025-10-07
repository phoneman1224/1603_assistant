# TL1 Assistant - SONET/SDH Network Element Management Tool

A comprehensive PowerShell GUI application for managing Alcatel 1603 SM and 16034 SMX SONET/SDH equipment via TL1 (Transaction Language 1) commands.

## 🚀 Quick Start

### **Easy Launch (Recommended)**
1. **Download** the repository from GitHub
2. **Extract** all files to a folder (e.g., `C:\TL1_Assistant\`)
3. **Double-click** `Start-TL1Assistant.cmd` to launch

### **Alternative Launch Methods**
- **PowerShell**: Right-click `Launch-TL1Assistant.ps1` → "Run with PowerShell"
- **Command Line**: `powershell -ExecutionPolicy Bypass -File Launch-TL1Assistant.ps1`

## ⚠️ **Important Requirements**

### **PowerShell Version**
- **Required**: Windows PowerShell 5.1 (comes with Windows 10/11)
- **NOT Compatible**: PowerShell Core/7+ (black icon)
- **Use**: Windows PowerShell (blue icon)

### **Windows Features**
- **.NET Framework 4.5+** (usually pre-installed)
- **Windows Desktop Experience** (GUI components)
- **Not supported**: Windows Server Core editions

## 🎯 Features

### **Command Database**
- **20 comprehensive TL1 commands** across 5 categories
- **Dynamic parameter validation** with real-time field rendering
- **Platform-specific filtering** for 1603 SM and 16034 SMX
- **Safety level indicators** and service-affecting warnings

### **Automation Playbooks**
- **10+ predefined automation sequences**
- **Health Check**: Complete system diagnostics
- **Troubleshooting**: Port testing, alarm investigation, equipment reset
- **Provisioning**: Service activation/deactivation, cross-connect creation
- **Maintenance**: Database backup, bulk operations

### **Advanced Features**
- **Structured logging** with background job execution
- **State persistence** (saves host, TID, CTAG between sessions)
- **Multi-step wizards** for complex provisioning tasks
- **Real-time command validation** and syntax checking

## 📁 Project Structure

```
1603_assistant/
├── Start-TL1Assistant.cmd          # Easy launcher (double-click to start)
├── Launch-TL1Assistant.ps1         # PowerShell launcher with diagnostics
├── powershell/
│   ├── TL1_CommandBuilder.ps1      # Main GUI application
│   └── appsettings.json            # Configuration settings
├── data/
│   ├── commands.json               # Complete TL1 command database
│   ├── playbooks.json              # Automation sequence definitions
│   └── schemas/                    # JSON validation schemas
├── docs/
│   ├── developer_guide.md          # Complete implementation guide
│   └── data_driven_implementation.md
└── scripts/
    └── build_database.py           # Database generation tools
```

## 🖥️ User Interface

### **Command Builder Tab**
- **Platform Selection**: Choose between 1603 SM and 16034 SMX
- **Category Tree**: Organized command categories
- **Dynamic Fields**: Auto-generated parameter inputs
- **Syntax Preview**: Real-time TL1 command construction
- **Execution**: Send commands to equipment with logging

### **Playbooks Tab**
- **Automation Library**: Pre-built troubleshooting and provisioning sequences
- **Step-by-Step Execution**: Guided workflow with progress tracking
- **Parameter Templates**: Reusable configurations
- **Error Handling**: Intelligent recovery and continuation options

### **Console Output**
- **Real-time Logging**: All command activity with timestamps
- **Structured Levels**: [SEND], [RECV], [INFO], [WARN], [ERROR], [TROUBLESHOOT]
- **Background Jobs**: Non-blocking command execution
- **Export Capability**: Save logs for analysis

## 🔧 Configuration

### **Connection Settings**
- **Host**: Target equipment IP address
- **Port**: TL1 port (typically 23)
- **Timeout**: Command response timeout
- **Auto-increment CTAG**: Automatic correlation tag management

### **Logging Options**
- **Log Directory**: Configurable log file location
- **Rotation**: Daily log file rotation
- **Debug Mode**: Detailed diagnostic output
- **Background Jobs**: Parallel command execution

## 🛠️ Troubleshooting

### **Script Won't Start**
1. **Check PowerShell Version**: Must be Windows PowerShell 5.1
2. **Execution Policy**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. **Run as Administrator**: Some features may require elevated privileges
4. **Windows Features**: Ensure Desktop Experience is installed

### **"Blinking" PowerShell Window**
- Usually indicates PowerShell Core instead of Windows PowerShell
- Use the provided launchers instead of running scripts directly
- Check the launcher output for specific error messages

### **GUI Doesn't Load**
1. **WPF Assemblies**: Ensure .NET Framework 4.5+ is installed
2. **Windows Version**: Requires Windows 10/11 or Server with Desktop Experience
3. **Virtual Machines**: May need 3D acceleration for WPF

### **Commands Fail to Execute**
1. **Network Connectivity**: Verify IP address and port
2. **Equipment State**: Ensure target device is accessible
3. **TL1 Syntax**: Check command format and parameters
4. **Permissions**: Verify user credentials and access rights

## 📖 Documentation

### **For Users**
- **INSTRUCTIONS.md**: Original project requirements and specifications
- **This README**: Quick start and troubleshooting guide

### **For Developers**
- **docs/developer_guide.md**: Complete architecture and API documentation
- **docs/data_driven_implementation.md**: Data structure and schema details
- **data/schemas/**: JSON validation schemas for commands and playbooks

## 🔄 Data-Driven Architecture

The TL1 Assistant uses a completely data-driven approach:

- **Commands**: Defined in `data/commands.json` with full paramSchema validation
- **Playbooks**: Automation sequences in `data/playbooks.json` with error handling
- **Schemas**: JSON Schema validation for data integrity
- **CI/CD**: Automated validation pipeline via GitHub Actions

This architecture enables:
- **Easy Maintenance**: Add new commands without code changes
- **Platform Flexibility**: Support new equipment types via configuration
- **Validation**: Automatic data integrity checking
- **Documentation**: Self-documenting command definitions

## 🎯 Use Cases

### **Network Operations**
- **Daily Health Checks**: Automated system status verification
- **Alarm Management**: Systematic alarm investigation and acknowledgment
- **Performance Monitoring**: Regular PM data collection and analysis

### **Service Provisioning**
- **Cross-Connect Creation**: Guided STS1 circuit provisioning
- **Service Activation**: Complete turn-up sequences with testing
- **Bulk Operations**: Mass provisioning with progress tracking

### **Troubleshooting**
- **Port Diagnostics**: Comprehensive connectivity testing
- **Equipment Reset**: Safe reset procedures with verification
- **Configuration Backup**: Database backup and restoration

## 🚀 Getting Started

1. **Download** from: https://github.com/phoneman1224/1603_assistant
2. **Extract** to your preferred directory
3. **Double-click** `Start-TL1Assistant.cmd`
4. **Configure** your equipment connection details
5. **Start** managing your SONET/SDH network!

## 📞 Support

For issues, enhancements, or questions:
- Check the troubleshooting section above
- Review the documentation in the `docs/` folder
- Examine log files for detailed error information

---

**TL1 Assistant** - Professional SONET/SDH network element management made simple.
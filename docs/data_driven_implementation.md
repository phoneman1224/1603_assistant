# Data-Driven TL1 Command Builder Implementation

## Overview
Successfully transformed the TL1 Command Builder from a hardcoded GUI into a smart, data-driven system with automated troubleshooting capabilities.

## ✅ Completed Features

### 1. Data-Driven Command Catalog (`data/commands.json`)
- **Purpose**: Replace hardcoded command lists with JSON-based catalog
- **Features**: 
  - 10 structured commands across 3 categories (Network Maintenance, System Administration, Cross Connect)
  - Complete paramSchema definitions with type validation
  - Enum values for intelligent ComboBox generation
  - Parameter descriptions and validation rules
- **Example**:
  ```json
  "RTRV-ALM": {
    "name": "Retrieve Alarms",
    "category": "Network Maintenance",
    "paramSchema": {
      "ALMCD": { "type": "enum", "values": ["ALL", "CR", "MJ", "MN"], "description": "Alarm condition" },
      "NTFCNCDE": { "type": "enum", "values": ["ALL", "CR", "MJ", "MN", "NA"], "description": "Notification code" }
    }
  }
  ```

### 2. Dynamic Field Rendering
- **Purpose**: Generate UI fields based on JSON paramSchema
- **Features**:
  - Enum parameters → ComboBox with predefined values
  - String parameters → TextBox for free input
  - Password parameters → PasswordBox with masking
  - Automatic field clearing and regeneration when command changes
- **Implementation**: `Refresh-OptionalFields` function with type-based UI generation

### 3. Automated Playbooks System (`data/playbooks.json`)
- **Purpose**: One-click troubleshooting sequences and automation
- **Features**:
  - **Port_Check**: 6-step diagnostic sequence (header check → alarms → equipment status → PM data → cross-connect verification → loopback test)
  - **Loopback_Test**: 4-step connectivity verification
  - **Cross_Connect_Wizard**: Multi-step provisioning workflow
  - Token substitution: `$TID`, `$AID`, `$CTAG` replaced with actual values
  - Step execution with delays and error handling
  - Console output with troubleshooting progress
- **Implementation**: `Invoke-Playbook` function with comprehensive execution logic

### 4. Settings Persistence (`settings.json`)
- **Purpose**: Maintain user preferences across application restarts
- **Features**:
  - Host/Port connection settings
  - TID/AID values for quick reuse
  - CTAG auto-increment functionality
  - Automatic save on application close
- **Implementation**: `Save-Settings` and `Load-Settings` functions

### 5. Enhanced UI Integration
- **Purpose**: Seamless integration of data-driven features
- **Features**:
  - "Run Troubleshooting" button connects to playbook system
  - Command dropdown populated from JSON catalog
  - Dynamic parameter fields based on selected command
  - Real-time command preview with token substitution
- **Implementation**: Event handlers and data binding throughout GUI

## 🏗️ Architecture Components

### File Structure
```
powershell/
├── TL1_CommandBuilder.ps1     # Main GUI application (extensively modified)
├── appsettings.json          # Application configuration
└── settings.json             # User preferences (auto-generated)

data/
├── commands.json             # Command catalog with paramSchema
└── playbooks.json           # Automated troubleshooting sequences
```

### Key Functions Added
- `Load-TL1Commands`: Parse commands.json and populate UI
- `Load-Playbooks`: Parse playbooks.json for automation
- `Refresh-OptionalFields`: Dynamic UI field generation
- `Invoke-Playbook`: Execute automated command sequences
- `Save-Settings` / `Load-Settings`: Persistent configuration

## 🧪 Testing Guide

### 1. Data Validation
```bash
# Verify JSON syntax (Linux/Mac)
python3 -c "import json; json.load(open('data/commands.json')); print('✅ commands.json valid')"
python3 -c "import json; json.load(open('data/playbooks.json')); print('✅ playbooks.json valid')"
```

### 2. GUI Testing (Windows)
1. **Launch Application**: Run `TL1_CommandBuilder.ps1`
2. **Test Command Loading**: 
   - Verify command dropdown populates from JSON
   - Select different commands and check dynamic fields
   - Confirm enum values show as ComboBoxes
3. **Test Settings Persistence**:
   - Enter Host/Port values
   - Close and restart application
   - Verify values are retained
4. **Test Troubleshooting**:
   - Enter TID and AID values
   - Click "Run Troubleshooting" button
   - Observe console output for Port_Check sequence
5. **Test Provisioning Wizard**:
   - Click "Provisioning Wizard" button
   - Complete 4-step Cross Connect wizard
   - Verify command generation in preview box

### 3. Data Extension Testing
1. **Add New Command**: Modify `commands.json` with new command definition
2. **Add New Playbook**: Create new troubleshooting sequence in `playbooks.json`
3. **Restart Application**: Verify new data loads correctly

## 📋 Configuration Schema

### Command Definition (`commands.json`)
```json
{
  "COMMAND_ID": {
    "name": "Human readable name",
    "category": "Category for organization",
    "description": "Command description",
    "paramSchema": {
      "PARAM_NAME": {
        "type": "enum|string|password",
        "values": ["option1", "option2"],  // For enum type
        "description": "Parameter description",
        "required": true|false
      }
    }
  }
}
```

### Playbook Definition (`playbooks.json`)
```json
{
  "PLAYBOOK_NAME": {
    "name": "Playbook display name",
    "description": "What this playbook does",
    "category": "troubleshooting|provisioning|diagnostics",
    "estimated_time": "Duration estimate",
    "steps": [
      {
        "step": 1,
        "name": "Step name",
        "command_id": "TL1_COMMAND",
        "description": "What this step does",
        "params": {
          "TID": "$TID",
          "CTAG": "$CTAG"
        },
        "delay_after": 2,
        "expected_responses": ["COMPLD"],
        "on_error": "continue|stop"
      }
    ]
  }
}
```

## 🚀 Next Steps Roadmap

### ✅ Phase 1: Provisioning Wizard (COMPLETED)
- ✅ Multi-step guided wizard for ENT-CRS commands
- ✅ Context-aware field validation  
- ✅ Cross-connect template library with 4-step workflow

### Phase 2: Enhanced Logging System (Next Priority)
- Structured logging with [SEND], [RECV], [TROUBLESHOOT] tags
- Daily log rotation and archival
- Error pattern detection

### Phase 3: Advanced Features
- Playbook condition evaluation (if/then logic)
- Response parsing and validation
- Custom user-defined playbooks
- Bulk command execution

## 🎯 Success Metrics
- ✅ **Data-Driven**: Commands loaded from JSON catalog
- ✅ **Dynamic UI**: Fields generated based on paramSchema
- ✅ **Automation**: One-click troubleshooting sequences
- ✅ **Persistence**: Settings saved across sessions
- ✅ **Extensibility**: Easy to add new commands and playbooks
- ✅ **Provisioning Wizard**: Multi-step guided workflows for complex operations

The TL1 Command Builder has been successfully transformed into an intelligent, data-driven system that provides both manual command building and automated troubleshooting capabilities.
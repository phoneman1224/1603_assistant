# TL1 Assistant Developer Guide

## Overview
The TL1 Assistant is a comprehensive automation platform for managing SONET/SDH equipment via TL1 (Transaction Language 1) commands. This guide covers the data-driven architecture, component structure, and development workflows.

## Architecture

### Data-Driven Design
The system is built on a data-driven architecture where all TL1 commands, automation sequences, and configurations are defined in JSON files with corresponding validation schemas.

```
data/
├── commands.json          # TL1 command database
├── playbooks.json         # Automation sequences
├── schemas/               # JSON validation schemas
│   ├── command_validation.schema.json
│   └── playbook_validation.schema.json
└── shared/                # Common data structures
```

### Core Components

#### 1. Command Database (`data/commands.json`)
- **Purpose**: Central repository of all TL1 commands with metadata
- **Structure**: 
  - `metadata`: Version, update tracking, platform info
  - `categories`: Command groupings (System Settings, Alarms, etc.)
  - `commands`: Array of command definitions with paramSchema

**Example Command Structure**:
```json
{
  "id": "RTRV_HDR",
  "name": "Retrieve Header",
  "syntax": "RTRV-HDR::TID:CTAG",
  "description": "Retrieves system header information",
  "category": "Retrieve Information",
  "platforms": ["1603_SM", "16034_SMX"],
  "paramSchema": {
    "type": "object",
    "properties": {
      "TID": {
        "type": "string",
        "description": "Target Identifier",
        "required": true
      }
    }
  }
}
```

#### 2. Playbooks (`data/playbooks.json`)
- **Purpose**: Automated sequences for complex operations
- **Categories**: Health Check, Troubleshooting, Provisioning, Maintenance
- **Structure**: Commands with step ordering, error handling, conditionals

**Example Playbook**:
```json
{
  "id": "System_Health_Check",
  "name": "Complete System Health Check",
  "description": "Comprehensive health assessment",
  "category": "Health Check",
  "commands": [
    {
      "step": 1,
      "command": "RTRV-HDR::{{TID}}:{{CTAG}}",
      "description": "Get system information",
      "onError": "stop"
    }
  ],
  "parameters": {
    "TID": {
      "type": "string",
      "description": "Equipment identifier",
      "required": true
    }
  }
}
```

### Platform Support
- **1603 SM**: Base SONET multiplexer platform
- **16034 SMX**: Extended multiplexer with additional interfaces
- **Shared Commands**: Commands available on both platforms
- **Platform-Specific**: Commands unique to specific hardware

## Development Workflow

### 1. Database Management
The command database is built using the deterministic script:

```bash
python3 scripts/build_database.py
```

This script:
- Scans platform-specific command directories
- Generates paramSchema for each command
- Validates TL1 syntax patterns
- Updates metadata automatically

### 2. Schema Validation
All JSON data is validated against schemas during CI:

```bash
# Validate commands.json
jsonschema -i data/commands.json data/schemas/command_validation.schema.json

# Validate playbooks.json  
jsonschema -i data/playbooks.json data/schemas/playbook_validation.schema.json
```

### 3. CI/CD Pipeline
Automated validation runs on every commit:
- JSON schema validation
- TL1 syntax verification
- Data consistency checks
- Cross-reference validation

## PowerShell GUI Framework

### Structured Logging System
The PowerShell interface includes comprehensive logging:

```powershell
# Log levels: [INFO], [WARN], [ERROR], [SEND], [RECV], [TROUBLESHOOT]
Write-Log "Command executed successfully" -Level "INFO" -Component "TL1Client"

# Background job execution
Start-TL1BackgroundCommand -Command $cmd -OnComplete $callback

# Job monitoring
Monitor-BackgroundJobs -ShowProgress
```

### Configuration Management
Settings are stored in `appsettings.json`:
```json
{
  "LogDir": "../logs",
  "DefaultHost": "",
  "DefaultPort": 23,
  "AutoIncrementCTAG": true,
  "Window": {"Width": 1150, "Height": 760},
  "Debug": true
}
```

## Adding New Commands

### 1. Create Command Definition
Add to appropriate platform directory:
```
data/platforms/[PLATFORM]/commands/new_command.json
```

### 2. Define Schema
Include parameter validation:
```json
{
  "paramSchema": {
    "type": "object",
    "properties": {
      "PARAMETER": {
        "type": "string",
        "description": "Parameter description",
        "required": true
      }
    }
  }
}
```

### 3. Rebuild Database
Run the build script to incorporate changes:
```bash
python3 scripts/build_database.py
```

## Creating Playbooks

### 1. Define Automation Sequence
Create ordered steps with error handling:
```json
{
  "commands": [
    {
      "step": 1,
      "command": "RTRV-ALM-ALL::{{TID}}:{{CTAG}}",
      "description": "Check for active alarms",
      "onError": "continue"
    },
    {
      "step": 2,
      "command": "RTRV-PM-ALL::{{TID}}:{{CTAG}}",
      "description": "Retrieve performance metrics",
      "conditional": "no_critical_alarms"
    }
  ]
}
```

### 2. Parameter Templating
Use `{{PARAMETER}}` syntax for dynamic values:
- Parameters defined in playbook schema
- Validated during execution
- Support for default values

### 3. Error Handling
Configure step behavior:
- `continue`: Proceed to next step
- `stop`: Halt playbook execution
- `retry`: Attempt command again
- `skip`: Skip step and continue

## Testing and Validation

### Local Testing
```bash
# Run comprehensive validation
./scripts/validate.sh

# Test specific components
python3 -m pytest tests/

# Validate JSON schema
python3 scripts/validate_schemas.py
```

### Test Vectors
The `tests/vectors/` directory contains:
- Sample command sequences
- Expected response patterns
- Error condition tests
- Cross-platform compatibility tests

## Best Practices

### Command Development
1. **Naming Convention**: Use `[VERB]_[OBJECT]` format for IDs
2. **Documentation**: Include comprehensive descriptions and examples
3. **Parameter Validation**: Define strict schemas for all parameters
4. **Platform Compatibility**: Test on both 1603_SM and 16034_SMX

### Playbook Design
1. **Atomic Steps**: Each step should be independently verifiable
2. **Error Recovery**: Define clear error handling strategies
3. **Time Estimation**: Provide realistic execution time estimates
4. **Prerequisites**: Document required system state

### Logging Strategy
1. **Structured Data**: Use consistent metadata format
2. **Appropriate Levels**: Choose correct severity levels
3. **Performance Impact**: Minimize logging overhead
4. **Retention Policy**: Implement log rotation and cleanup

## Troubleshooting

### Common Issues
1. **Schema Validation Failures**: Check JSON syntax and required fields
2. **Command Syntax Errors**: Verify TL1 format compliance
3. **Platform Compatibility**: Ensure commands exist on target platform
4. **Parameter Binding**: Validate parameter types and requirements

### Debug Mode
Enable debug logging in `appsettings.json`:
```json
{"Debug": true}
```

This provides:
- Detailed command parsing
- Parameter substitution traces
- Response timing information
- Error stack traces

## Contributing

### Pull Request Process
1. Create feature branch from `develop`
2. Implement changes with tests
3. Run full validation suite
4. Submit PR with clear description
5. Address CI feedback

### Code Review Checklist
- [ ] Schema validation passes
- [ ] Documentation updated
- [ ] Test coverage adequate
- [ ] Cross-platform compatibility verified
- [ ] Performance impact assessed

## Reference

### TL1 Command Format
```
[VERB]-[OBJECT]::[TID]:[CTAG][::[PARAMETERS]]
```

### Standard Response Format
```
[TID] [DATE] [TIME]
M [CTAG] COMPLD
"[RESPONSE_DATA]"
;
```

### Error Codes
- `DENY`: Access denied
- `IIRT`: Input, Invalid or Requested, Too many
- `ICNV`: Input, Conflicting or Not Valid
- `SROF`: System Resource, Outage or Failure

For additional details, see the platform-specific documentation in `data/platforms/[PLATFORM]/docs/`.
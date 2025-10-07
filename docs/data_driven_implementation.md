# Data-Driven TL1 Assistant Implementation

## Overview

The TL1 Assistant is designed as a comprehensive data-driven automation platform that separates command definitions, automation sequences, and configuration from the execution logic. This architecture enables rapid adaptation to new platforms, easy maintenance, and robust validation.

## Architecture Principles

### 1. Separation of Concerns
- **Data Layer**: JSON files define commands, playbooks, and configurations
- **Logic Layer**: Python/PowerShell handles execution and validation
- **UI Layer**: PowerShell GUI provides user interaction
- **Validation Layer**: JSON schemas ensure data integrity

### 2. Platform Abstraction
Commands are defined with platform compatibility metadata, allowing the same interface to work across multiple SONET/SDH equipment types while respecting platform-specific capabilities.

### 3. Schema-Driven Validation
All data structures are validated against JSON schemas, ensuring consistency and catching errors before execution.

## Core Data Structures

### Command Database (`data/commands.json`)

```json
{
  "metadata": {
    "version": "2.0",
    "lastUpdate": "2024-01-20",
    "totalCommands": 20,
    "platforms": ["1603_SM", "16034_SMX"]
  },
  "categories": [
    "System Settings/Maintenance",
    "Alarms", 
    "Retrieve Information",
    "Troubleshooting",
    "Provisioning"
  ],
  "commands": [
    {
      "id": "RTRV_HDR",
      "name": "Retrieve Header",
      "syntax": "RTRV-HDR::TID:CTAG",
      "description": "Retrieves system header information including software version and equipment ID",
      "category": "Retrieve Information",
      "platforms": ["1603_SM", "16034_SMX"],
      "paramSchema": {
        "type": "object",
        "properties": {
          "TID": {
            "type": "string",
            "description": "Target Identifier for the network element",
            "required": true,
            "pattern": "^[A-Z0-9_-]+$"
          },
          "CTAG": {
            "type": "string",
            "description": "Correlation Tag for command tracking",
            "required": true,
            "pattern": "^[0-9]+$"
          }
        },
        "required": ["TID", "CTAG"]
      },
      "examples": [
        {
          "description": "Get header for equipment ID SM01",
          "command": "RTRV-HDR::SM01:123",
          "response": "SM01 2024-01-20 14:30:15\nM 123 COMPLD\n\"EQPT=1603SM,SW=R12.0.1,HW=REV_A\"\n;"
        }
      ]
    }
  ]
}
```

### Playbook System (`data/playbooks.json`)

```json
{
  "metadata": {
    "version": "2.0",
    "lastUpdate": "2024-01-20",
    "totalPlaybooks": 10
  },
  "playbooks": [
    {
      "id": "System_Health_Check",
      "name": "Complete System Health Check",
      "description": "Comprehensive health assessment including alarms, performance, and configuration verification",
      "category": "Health Check",
      "estimatedTime": "2-3 minutes",
      "platforms": ["1603_SM", "16034_SMX"],
      "prerequisites": [
        "Equipment must be online and accessible",
        "Valid TID configured"
      ],
      "commands": [
        {
          "step": 1,
          "command": "RTRV-HDR::{{TID}}:{{CTAG}}",
          "description": "Get system information and verify connectivity",
          "onError": "stop"
        },
        {
          "step": 2,
          "command": "RTRV-ALM-ALL::{{TID}}:{{CTAG+1}}:{{ALMLEV}}",
          "description": "Check for any active alarms",
          "onError": "continue"
        },
        {
          "step": 3,
          "command": "RTRV-PM-ALL::{{TID}}:{{CTAG+2}}",
          "description": "Retrieve current performance metrics",
          "conditional": "no_critical_alarms",
          "onError": "continue"
        }
      ],
      "parameters": {
        "TID": {
          "type": "string",
          "description": "Equipment target identifier",
          "required": true
        },
        "CTAG": {
          "type": "integer",
          "description": "Starting correlation tag number",
          "required": true,
          "default": 100
        },
        "ALMLEV": {
          "type": "string",
          "description": "Alarm severity level filter",
          "required": false,
          "enum": ["ALL", "CR", "MJ", "MN", "WG"],
          "default": "ALL"
        }
      },
      "postConditions": [
        "System connectivity verified",
        "Alarm status assessed",
        "Performance baseline established"
      ]
    }
  ]
}
```

## Implementation Components

### 1. Database Builder (`scripts/build_database.py`)

Generates the command database from platform-specific sources:

```python
def build_command_database():
    """Build comprehensive TL1 command database"""
    commands = []
    
    # Core system commands
    commands.extend(build_system_commands())
    commands.extend(build_alarm_commands())
    commands.extend(build_retrieval_commands())
    commands.extend(build_troubleshooting_commands())
    commands.extend(build_provisioning_commands())
    
    # Generate metadata
    metadata = {
        "version": "2.0",
        "lastUpdate": datetime.now().strftime("%Y-%m-%d"),
        "totalCommands": len(commands),
        "platforms": ["1603_SM", "16034_SMX"]
    }
    
    return {"metadata": metadata, "categories": categories, "commands": commands}
```

### 2. Schema Validation

JSON schemas ensure data integrity:

```python
def validate_commands_schema(commands_data):
    """Validate commands.json against schema"""
    with open('data/schemas/command_validation.schema.json') as f:
        schema = json.load(f)
    
    try:
        jsonschema.validate(commands_data, schema)
        return True, None
    except jsonschema.ValidationError as e:
        return False, str(e)
```

### 3. PowerShell Integration

The PowerShell GUI loads and uses the JSON data:

```powershell
# Load command database
$CommandsPath = Join-Path $DataDir "commands.json"
$Commands = Get-Content $CommandsPath -Raw | ConvertFrom-Json

# Load playbooks
$PlaybooksPath = Join-Path $DataDir "playbooks.json" 
$Playbooks = Get-Content $PlaybooksPath -Raw | ConvertFrom-Json

# Execute parameterized command
function Invoke-TL1Command {
    param($CommandId, $Parameters)
    
    $cmd = $Commands.commands | Where-Object { $_.id -eq $CommandId }
    $syntax = $cmd.syntax
    
    # Parameter substitution
    foreach ($param in $Parameters.GetEnumerator()) {
        $syntax = $syntax -replace "\{\{$($param.Key)\}\}", $param.Value
    }
    
    Write-Log "Executing: $syntax" -Level "SEND"
    # Execute command...
}
```

## Advanced Features

### 1. Parameter Templating

Commands support dynamic parameter substitution:
- `{{PARAMETER}}`: Direct substitution
- `{{CTAG+1}}`: Arithmetic operations
- `{{PARAMETER|DEFAULT}}`: Default values
- Conditional logic for optional parameters

### 2. Error Handling Strategies

Playbooks define granular error handling:
- **stop**: Halt execution on error
- **continue**: Log error and proceed
- **retry**: Attempt command again
- **skip**: Skip step if condition not met

### 3. Background Execution

PowerShell supports non-blocking command execution:

```powershell
function Start-TL1BackgroundCommand {
    param($Command, $OnComplete)
    
    $job = Start-Job -ScriptBlock {
        param($cmd) 
        # Execute TL1 command
        Invoke-TL1Command $cmd
    } -ArgumentList $Command
    
    # Store job reference for monitoring
    $script:BackgroundJobs[$job.Id] = @{
        Job = $job
        Command = $Command
        StartTime = Get-Date
        OnComplete = $OnComplete
    }
}
```

### 4. Structured Logging

Comprehensive logging with metadata:

```powershell
function Write-Log {
    param($Message, $Level = "INFO", $Component = "TL1Assistant")
    
    $logEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
        level = $Level
        component = $Component
        message = $Message
        thread = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    }
    
    Add-Content $LogFile ($logEntry | ConvertTo-Json -Compress)
}
```

## Platform-Specific Adaptations

### Command Filtering

The system automatically filters commands based on platform capabilities:

```python
def filter_commands_by_platform(commands, target_platform):
    """Filter commands available for specific platform"""
    return [cmd for cmd in commands if target_platform in cmd['platforms']]
```

### Configuration Profiles

Platform-specific settings are maintained separately:

```json
{
  "1603_SM": {
    "defaultPort": 23,
    "maxConnections": 4,
    "commandTimeout": 30,
    "supportedInterfaces": ["OC3", "DS3", "DS1"]
  },
  "16034_SMX": {
    "defaultPort": 23,
    "maxConnections": 8,
    "commandTimeout": 45,
    "supportedInterfaces": ["OC12", "OC3", "DS3", "DS1", "ETH"]
  }
}
```

## CI/CD Integration

### Automated Validation Pipeline

GitHub Actions workflow validates all data changes:

```yaml
name: Validate Data Schema
on:
  push:
    paths: ['data/**/*.json']
    
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate Commands
        run: |
          python -c "
          import json, jsonschema
          with open('data/schemas/command_validation.schema.json') as f:
              schema = json.load(f)
          with open('data/commands.json') as f:
              data = json.load(f)
          jsonschema.validate(data, schema)
          print('✅ commands.json validation passed')
          "
```

### Data Consistency Checks

Cross-reference validation ensures playbooks reference valid commands:

```python
def validate_playbook_references(playbooks, commands):
    """Ensure playbook commands reference valid command IDs"""
    command_ids = {cmd['id'] for cmd in commands['commands']}
    errors = []
    
    for playbook in playbooks['playbooks']:
        for step in playbook['commands']:
            cmd_ref = extract_command_id(step['command'])
            if cmd_ref not in command_ids:
                errors.append(f"Invalid command reference: {cmd_ref}")
    
    return errors
```

## Performance Considerations

### Lazy Loading

Large datasets are loaded on-demand:

```powershell
$script:CommandCache = @{}

function Get-Command {
    param($CommandId)
    
    if (!$script:CommandCache.ContainsKey($CommandId)) {
        $script:CommandCache[$CommandId] = Load-CommandDefinition $CommandId
    }
    
    return $script:CommandCache[$CommandId]
}
```

### Efficient Filtering

Pre-computed indexes speed up command lookups:

```python
def build_command_index(commands):
    """Build lookup indexes for fast command retrieval"""
    return {
        'by_id': {cmd['id']: cmd for cmd in commands},
        'by_category': group_by_category(commands),
        'by_platform': group_by_platform(commands)
    }
```

## Maintenance and Updates

### Automated Database Updates

The build script can be run automatically to incorporate new commands:

```bash
#!/bin/bash
# scripts/update_database.sh

echo "🔄 Updating command database..."
python3 scripts/build_database.py

echo "✅ Validating updated data..."
python3 scripts/validate_schemas.py

echo "📝 Updating documentation..."
python3 scripts/generate_docs.py

git add data/commands.json docs/
git commit -m "Auto-update: Command database refresh"
```

### Version Management

Database versions track schema evolution:

```json
{
  "metadata": {
    "version": "2.1",
    "schemaVersion": "1.0",
    "compatibilityLevel": "2.0",
    "migrationRequired": false
  }
}
```

This data-driven approach ensures the TL1 Assistant remains maintainable, extensible, and reliable while supporting complex telecommunications operations across multiple equipment platforms.
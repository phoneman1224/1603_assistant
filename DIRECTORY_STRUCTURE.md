# Directory Structure for 1603 Assistant

This document outlines the recommended file structure for adding documentation to the repository.

## Recommended Structure

```
1603_assistant/
├── data/
│   └── platforms/
│       └── alcatel_1603/
│           ├── README.md                      # This file
│           ├── tl1_syntax.md                  # TL1 command syntax reference
│           ├── commands/
│           │   ├── command_examples.json      # JSON database of commands
│           │   └── index.json                 # Command index
│           ├── tap_procedures/                # Troubleshooting procedures
│           │   ├── TAP-001.md                # Identifying alarms
│           │   ├── TAP-002.md                # Clearing alarms
│           │   └── ...                       # Additional TAPs
│           ├── dlp_procedures/                # Operational procedures
│           │   ├── DLP-101.md                # Emergency response
│           │   └── ...                       # Additional DLPs
│           └── docs/
│               ├── user_guide.md             # User documentation
│               └── equipment_specs.md        # Equipment specifications
├── src/
│   ├── gui/
│   │   ├── __init__.py
│   │   ├── main_window.py                    # Main GUI application
│   │   ├── tl1_builder.py                    # TL1 command builder widget
│   │   └── ai_assistant.py                   # AI assistant integration
│   ├── telnet/
│   │   ├── __init__.py
│   │   └── connection.py                     # Telnet connection handler
│   ├── commands/
│   │   ├── __init__.py
│   │   ├── tl1_parser.py                     # TL1 command parser
│   │   └── validator.py                      # Command validator
│   └── utils/
│       ├── __init__.py
│       └── logger.py                         # Logging utilities
├── requirements.txt                           # Python dependencies
├── launch.py                                  # Application entry point
└── README.md                                  # Main project README
```

## File Descriptions

### Documentation Files (data/platforms/alcatel_1603/)

#### tl1_syntax.md
Complete TL1 command syntax reference including:
- Command format and structure
- Vacant parameter rules (CRITICAL!)
- Common verbs, modifiers, and objects
- Command examples
- Best practices

#### commands/command_examples.json
JSON database containing:
- Categorized command examples
- Parameter definitions
- Response codes
- Error codes
- AID patterns

#### tap_procedures/
Troubleshooting Action Procedures:
- Step-by-step troubleshooting guides
- Alarm identification and resolution
- Equipment diagnostics
- Decision trees

#### dlp_procedures/
Documented Local Practices:
- Operational procedures
- Provisioning workflows
- Maintenance tasks
- Emergency procedures

### Source Code Files (src/)

#### gui/main_window.py
Main application window with:
- Connection panel
- Command builder interface
- Response display
- AI assistant integration

#### gui/tl1_builder.py
TL1 command builder widget:
- Dropdowns for verbs, modifiers, objects
- Input fields for TID, AID, CTAG, parameters
- Command preview with proper vacant parameter handling
- Send command functionality

#### gui/ai_assistant.py
AI assistant logic:
- Natural language processing
- TAP/DLP procedure matching
- Command suggestion
- Step-by-step guidance

#### telnet/connection.py
Telnet connection handler:
- Connect/disconnect functionality
- Command transmission
- Response parsing
- Autonomous message handling

#### commands/tl1_parser.py
TL1 command parser:
- Parse TL1 syntax
- Validate command structure
- Handle vacant parameters correctly
- Format commands properly

## How to Add Files

### Adding Documentation

1. Create markdown files in appropriate directories
2. Follow the naming convention: `TAP-###.md` or `DLP-###.md`
3. Include proper headers and formatting
4. Cross-reference related procedures

### Adding Commands

1. Update `command_examples.json` with new commands
2. Include all parameters and descriptions
3. Provide clear examples
4. Specify which parameters can be vacant

### Adding Source Code

1. Create Python modules in appropriate src/ subdirectories
2. Use proper imports and dependencies
3. Follow PEP 8 style guidelines
4. Include docstrings

## Integration Points

### AI Assistant Triggers

The AI assistant uses keyword matching from user input:

```python
# Example triggers
"I see alarms" → Load TAP-001
"provision T1" → Load DLP for T1 provisioning
"OC12 troubleshooting" → Load TAP-005
```

### Command Builder Integration

The command builder reads from:
- `tl1_syntax.md` for syntax rules
- `command_examples.json` for dropdowns and examples
- TAP/DLP files for suggested commands

## Next Steps

1. **Copy these files to your repository:**
   - tl1_syntax.md → data/platforms/alcatel_1603/
   - command_examples.json → data/platforms/alcatel_1603/commands/
   - TAP-001.md → data/platforms/alcatel_1603/tap_procedures/

2. **Tell GitHub Copilot to build the GUI using these files**

3. **Test and iterate**

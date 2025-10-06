# Platform-Specific Documentation and Data

This directory contains platform-specific information for different 1603 variants.

## Directory Structure

```
platforms/
├── 1603_SM/
│   ├── commands/      # Platform-specific command variations
│   ├── docs/         # Platform documentation
│   └── schemas/      # Platform-specific schemas and constraints
└── 16034_SMX/
    ├── commands/      # Platform-specific command variations
    ├── docs/         # Platform documentation
    └── schemas/      # Platform-specific schemas and constraints
```

## Platform Files

### 1603_SM
- Place 1603_SM specific documentation and configuration files here
- Command variations specific to 1603_SM
- Platform-specific schemas and validation rules

### 16034_SMX
- Place 16034_SMX specific documentation and configuration files here
- Command variations specific to 16034_SMX
- Platform-specific schemas and validation rules

## File Organization Guidelines

1. **Documentation (docs/)**
   - Technical specifications
   - Platform limitations
   - Installation guides
   - Troubleshooting guides
   - Release notes

2. **Commands (commands/)**
   - Platform-specific command sets
   - Command limitations
   - Platform-specific parameters
   - Response variations

3. **Schemas (schemas/)**
   - JSON schemas for validation
   - Parameter constraints
   - Platform-specific enums and ranges

## Usage

When adding new files:
1. Place in appropriate platform subdirectory
2. Update relevant README files
3. Maintain consistent file naming
4. Include proper documentation
5. Update cross-references if needed
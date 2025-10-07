# Provisioning Wizard Implementation

## Overview
The Provisioning Wizard provides a guided, multi-step interface for complex TL1 provisioning operations, making cross-connect establishment and facility configuration more intuitive and less error-prone.

## ✨ Features Implemented

### 1. Multi-Step Guided Workflow
- **Progressive Interface**: Break complex provisioning into digestible steps
- **Visual Progress**: Progress bar and step indicators
- **Navigation**: Back/Next buttons with validation
- **Dynamic Content**: Context-sensitive field rendering

### 2. Wizard Framework Architecture

#### Components:
- **`Show-ProvisioningWizard`**: Main wizard launcher and window manager
- **`Show-WizardStep`**: Dynamic step rendering engine
- **`Validate-WizardStep`**: Field validation and data collection
- **`Execute-Wizard`**: Final provisioning execution

#### XAML Interface:
```xml
- Wizard Header (title, description, progress)
- Dynamic Content Area (auto-generated from wizard_steps)
- Navigation Controls (Back, Next/Provision, Cancel)
```

### 3. Data-Driven Wizard Definition

#### Wizard Structure (`playbooks.json`):
```json
"Cross_Connect_Wizard": {
  "name": "STS-1 Cross Connect Provisioning",
  "description": "Guided provisioning of STS-1 cross-connections with validation",
  "wizard_steps": [
    {
      "step": 1,
      "name": "Service Type Selection",
      "fields": [
        {
          "name": "service_type",
          "type": "enum",
          "values": ["STS1", "VT15", "VT6"],
          "required": true
        }
      ]
    }
  ]
}
```

### 4. Field Type Support
- **Enum Fields**: Rendered as ComboBox with predefined values
- **String Fields**: Rendered as TextBox with pattern validation
- **Required Validation**: Visual indicators and validation
- **Default Values**: Auto-populated where specified
- **Examples**: Tooltips for guidance

### 5. Integration Points
- **GUI Button**: "Provisioning Wizard" button in main interface
- **Data Persistence**: Wizard state maintained across steps
- **Command Generation**: Automatic TL1 command building
- **Preview Integration**: Generated commands shown in preview box

## 🎯 Cross-Connect Wizard Workflow

### Step 1: Service Type Selection
- **Purpose**: Choose the type of cross-connection
- **Fields**: 
  - Service Type (STS1/VT15/VT6) - Enum dropdown
- **Validation**: Required selection

### Step 2: Endpoint Configuration  
- **Purpose**: Configure source and destination facilities
- **Fields**:
  - Source AID (LG1-STS1-1 format) - TextBox with pattern validation
  - Destination AID (LG2-STS1-1 format) - TextBox with pattern validation
- **Validation**: Required fields, pattern matching

### Step 3: Connection Options
- **Purpose**: Set cross-connection parameters
- **Fields**:
  - Connection Type (2WAY/1WAY) - Enum dropdown with default
- **Validation**: Optional with default value

### Step 4: Confirmation & Execution
- **Purpose**: Review and execute provisioning
- **Action**: Generate and execute ENT-CRS-STS1 command
- **Command**: `ENT-CRS-STS1:[tid]:[ctag]::source,dest,[type];`

## 🔧 Technical Implementation

### Wizard State Management
```powershell
$wizardState = @{
    wizard = $wizard           # Wizard definition from JSON
    currentStep = 1            # Current step number
    totalSteps = 4             # Total wizard steps
    data = @{}                 # Collected field data
}
```

### Dynamic Field Rendering
- **Enum → ComboBox**: Automatic dropdown generation
- **String → TextBox**: Text input with validation
- **Tooltips**: Example values and guidance
- **State Preservation**: Field values maintained during navigation

### Validation Engine
```powershell
# Required field validation
if ($fieldDef.required -and [string]::IsNullOrWhiteSpace($value)) {
    $isValid = $false
}

# Pattern validation for facility identifiers
if ($fieldDef.pattern -and $value -notmatch $fieldDef.pattern) {
    $isValid = $false
}
```

### Command Generation
```powershell
$command = "ENT-CRS-STS1:${tid}:${ctag}::${sourceAid},${destAid},${connType};"
```

## 📋 Usage Instructions

### 1. Launch Wizard
1. Click "Provisioning Wizard" button in main GUI
2. Cross Connect Wizard window opens
3. Follow step-by-step prompts

### 2. Navigation
- **Next**: Proceed to next step (validates current step)
- **Back**: Return to previous step (preserves data)
- **Cancel**: Close wizard without changes
- **Provision**: Execute final command (last step)

### 3. Field Validation
- Required fields marked with asterisk (*)
- Real-time validation on step navigation
- Pattern validation for facility identifiers
- Error messages logged to console

### 4. Command Preview
- Generated command appears in main preview box
- Can be copied or sent like manual commands
- CTAG automatically incremented

## 🚀 Extension Points

### Adding New Wizards
1. **Define Wizard**: Add to `playbooks.json` under "Provisioning"
2. **Button Handler**: Update wizard launcher to support new wizard
3. **Testing**: Validate field definitions and flow

### Custom Field Types
- Extend field type support in `Show-WizardStep`
- Add validation rules in `Validate-WizardStep`
- Support for date, number, multi-select fields

### Advanced Features
- **Conditional Steps**: Show/hide steps based on previous selections
- **Pre-validation**: Check facility availability before provisioning
- **Rollback**: Automatic deletion commands for failed provisions
- **Templates**: Save/load common provisioning configurations

## 🧪 Testing Scenarios

### Wizard Launch
1. Click "Provisioning Wizard" button
2. Verify window opens with correct title
3. Check step 1 content loads properly

### Navigation Testing
1. Complete step 1 → Next (should advance)
2. Leave required field empty → Next (should show error)
3. Navigate Back → Forward (should preserve data)

### Field Validation
1. Enter invalid facility ID (should reject)
2. Leave required field empty (should prevent advance)
3. Select enum values (should populate correctly)

### Command Generation
1. Complete all steps with valid data
2. Click "Provision" 
3. Verify command appears in preview box
4. Check CTAG incrementation

## 📊 Success Metrics
- ✅ **Multi-Step Interface**: 4-step wizard with progress indicators
- ✅ **Dynamic Rendering**: Fields generated from JSON definitions
- ✅ **Validation Engine**: Required fields and pattern matching
- ✅ **Command Generation**: Automatic ENT-CRS-STS1 building
- ✅ **GUI Integration**: Seamless launch from main interface

The Provisioning Wizard transforms complex TL1 provisioning from error-prone manual command building into a guided, validated workflow that reduces mistakes and improves efficiency.
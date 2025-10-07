# Windows Testing Checklist for 1603 Assistant

## Prerequisites
- Windows 10/11 (desktop environment required for WPF)
- Windows PowerShell 5.1 (comes with Windows, blue icon)
- Python 3.8+ installed and accessible from command line
- Git for Windows (if cloning repository)

## Pre-Testing Setup

1. **Clone or download repository**
   ```cmd
   git clone https://github.com/phoneman1224/1603_assistant.git
   cd 1603_assistant
   ```

2. **Run Windows bootstrap (optional but recommended)**
   ```cmd
   cd init
   windows_bootstrap.cmd
   ```

## Test Scenarios

### ✅ Test 1: PowerShell GUI Launch
**Goal**: Verify the main GUI application starts correctly

**Steps**:
1. Double-click `Start-TL1.cmd` in the root directory
2. Verify PowerShell GUI window opens
3. Check that:
   - Window displays "TL1 Command Builder" title
   - Connection panel shows Host/Port fields
   - System dropdown has "1603 SM" and "16034 SMX" options
   - Category tree shows command categories
   - Console output area is visible

**Expected Result**: GUI opens without errors, all components visible

**Troubleshooting**:
- If "PowerShell version" error: Make sure using Windows PowerShell (blue icon), not PowerShell Core
- If WPF errors: Ensure Windows Desktop features are installed
- Check `debug.log` file created in root directory for error details

### ✅ Test 2: Python CLI Validation
**Goal**: Verify Python components work with Windows paths

**Steps**:
1. Open Command Prompt or PowerShell in repository root
2. Test working catalog search:
   ```cmd
   python src/entrypoint.py --catalog dlp --find DLP-203
   ```
3. Test file parsing:
   ```cmd
   python src/entrypoint.py --parse tests/vectors/oc12/RST-OC12_clear_LOS/raw.txt
   ```

**Expected Result**: 
- DLP catalog search returns JSON data for the procedure
- File parsing returns JSON with header, body, footer structure

**Note**: TL1 catalog validation may show schema mismatches - this is not critical for GUI operation

**Troubleshooting**:
- If "No module named" errors: Run `pip install -r requirements.txt`
- If path errors: Verify `data/` directory structure exists

### ✅ Test 3: File Parsing Test
**Goal**: Verify TL1 file parsing works

**Steps**:
1. Find a test file in `tests/vectors/` directory
2. Run parser:
   ```cmd
   python src/entrypoint.py --parse tests/vectors/discovery/RTRV-HDR_basic/raw.txt
   ```

**Expected Result**: JSON output showing parsed header, body, footer

### ✅ Test 4: GUI Connection Test
**Goal**: Test network connection capabilities

**Steps**:
1. Launch GUI via `Start-TL1.cmd`
2. Enter a test host (can be invalid for this test)
3. Enter port 23
4. Click "Connect"
5. Verify error handling for invalid connections

**Expected Result**: Appropriate error messages, no crashes

### ✅ Test 5: Command Building Test
**Goal**: Verify command generation works with comprehensive PDF-extracted documentation

**Steps**:
1. In GUI, expand a category from the tree (e.g., "Network Maintenance")
2. Select a command (e.g., "RTRV-HDR")
3. Verify comprehensive information is displayed:
   - Source PDF file name
   - Detailed description and function
   - Restrictions in red text
   - Required parameters with red borders and detailed descriptions
   - Optional parameters with detailed descriptions
   - Complete syntax reference
   - Response format examples
4. Fill in required parameters and test command building
5. Try commands with safety warnings (e.g., commands starting with "DLT-")

**Expected Result**: 
- **56+ commands** from extracted PDF documentation
- **Rich parameter descriptions** from official documentation
- **Safety warnings** for dangerous operations
- **Complete syntax and response format** information
- **Well-formed TL1 commands** with proper format

**Enhanced Features to Test**:
- **Detailed parameter help**: Each parameter shows full description from PDF
- **Source tracking**: Shows which PDF the command came from
- **Restrictions display**: Shows operational restrictions in red
- **Response format**: Shows expected response patterns
- **Categories from documentation**: Network Maintenance, Security Administration, Memory Administration, System Maintenance

**Test Specific Commands**:
- **RTRV-HDR**: Simple system information command
- **ALW-LPBK-T1**: Complex loopback command with detailed parameters
- **CANC-USER**: Security command with safety implications
- **OPR-LPBK-T3**: Network testing command with multiple parameters

## Performance Tests

### Test 6: File Loading Performance
**Goal**: Ensure data files load reasonably fast on Windows

**Steps**:
1. Measure startup time of GUI
2. Measure validation time: `python src/entrypoint.py --validate`

**Expected Result**: 
- GUI startup: < 5 seconds
- Validation: < 10 seconds

## Integration Tests

### Test 7: End-to-End Workflow
**Goal**: Complete workflow from GUI to command execution

**Steps**:
1. Start GUI
2. Configure connection settings
3. Browse and select a command
4. Build command with parameters
5. Send command (if safe test environment available)

**Expected Result**: Complete workflow without errors

## Compatibility Notes

### Windows-Specific Features Verified:
- ✅ Windows PowerShell 5.1 compatibility checks
- ✅ WPF assembly loading with proper error handling
- ✅ STA threading mode for WPF components
- ✅ Windows path handling (backslashes vs forward slashes)
- ✅ Registry and file system permission handling
- ✅ Debug logging to local files

### Known Limitations:
- Requires Windows desktop environment (no Windows Server Core)
- PowerShell execution policy may need adjustment
- Some antivirus software may flag PowerShell GUI execution

## Troubleshooting Guide

### Common Issues:

1. **"Execution Policy" Error**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **"Assembly not found" WPF Error**
   - Ensure Windows Desktop Experience is installed
   - Try running from elevated PowerShell

3. **Python Module Errors**
   ```cmd
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

4. **Path/Directory Errors**
   - Verify complete repository structure
   - Check that data/ directory contains platforms/ and shared/ subdirectories

## Reporting Issues

When reporting Windows-specific issues, please include:
- Windows version (e.g., Windows 10 21H2)
- PowerShell version (`$PSVersionTable.PSVersion`)
- Python version (`python --version`)
- Contents of `debug.log` file
- Exact error messages and steps to reproduce
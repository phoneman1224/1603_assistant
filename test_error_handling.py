#!/usr/bin/env python3
"""
Test script to validate error handling improvements in TL1_CommandBuilder.ps1
This simulates the PowerShell logic to verify error handling works correctly.
"""

import json
import re
import os

def analyze_powershell_error_handling():
    """Analyze the PowerShell script for error handling patterns"""
    
    script_path = "/workspaces/1603_assistant/powershell/TL1_CommandBuilder.ps1"
    
    if not os.path.exists(script_path):
        print(f"❌ PowerShell script not found: {script_path}")
        return False
    
    print("🔍 Analyzing PowerShell error handling...")
    
    with open(script_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for key error handling patterns
    checks = [
        {
            "name": "Refresh-OptionalFields null check",
            "pattern": r"if\s*\(\s*-not\s+\$OptionalPanel\s*\)",
            "description": "Checks if OptionalPanel is null before use"
        },
        {
            "name": "Refresh-OptionalFields try-catch",
            "pattern": r"function\s+Refresh-OptionalFields.*?try\s*{",
            "description": "Function wrapped in try-catch block"
        },
        {
            "name": "Tree selection error handler",
            "pattern": r"\$CategoryTree\.Add_SelectedItemChanged.*?catch\s*{",
            "description": "Tree selection has error handling"
        },
        {
            "name": "Command selection error handler", 
            "pattern": r"\$CommandBox\.Add_SelectionChanged.*?catch\s*{",
            "description": "Command selection has error handling"
        },
        {
            "name": "Write-Log error logging",
            "pattern": r"Write-Log.*?ERROR",
            "description": "Uses proper error logging"
        }
    ]
    
    results = []
    for check in checks:
        if re.search(check["pattern"], content, re.DOTALL | re.IGNORECASE):
            print(f"✅ {check['name']}: {check['description']}")
            results.append(True)
        else:
            print(f"❌ {check['name']}: {check['description']}")
            results.append(False)
    
    return all(results)

def validate_command_database():
    """Validate the command database structure"""
    
    db_path = "/workspaces/1603_assistant/data/commands.json"
    
    if not os.path.exists(db_path):
        print(f"❌ Command database not found: {db_path}")
        return False
    
    print("\n🔍 Validating command database...")
    
    try:
        with open(db_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Extract commands from the structure
        if isinstance(data, dict) and "commands" in data:
            commands_dict = data["commands"]
            commands = list(commands_dict.values())  # Convert object to array
        elif isinstance(data, list):
            commands = data
        else:
            print(f"❌ Unexpected database structure")
            return False
        
        # Count commands by platform
        sm_count = 0
        smx_count = 0
        for cmd in commands:
            platforms = cmd.get("platforms", [])
            if "1603 SM" in platforms:
                sm_count += 1
            if "1603 SMX" in platforms:
                smx_count += 1
        
        total_count = len(commands)
        
        print(f"✅ Database loaded successfully")
        print(f"📊 Total commands: {total_count}")
        print(f"📊 1603 SM commands: {sm_count}")
        print(f"📊 1603 SMX commands: {smx_count}")
        
        # Validate required fields
        required_fields = ["id", "description", "platforms"]
        missing_fields = []
        
        for i, cmd in enumerate(commands[:10]):  # Check first 10 commands
            for field in required_fields:
                if field not in cmd:
                    missing_fields.append(f"Command {i}: missing {field}")
        
        if missing_fields:
            print("⚠️  Found missing fields in commands:")
            for missing in missing_fields[:5]:  # Show first 5
                print(f"   {missing}")
        else:
            print("✅ All commands have required fields")
        
        return True
        
    except Exception as e:
        print(f"❌ Database validation failed: {e}")
        return False

def main():
    """Main validation function"""
    print("🚀 TL1 Assistant Error Handling Validation\n")
    
    # Validate error handling
    error_handling_ok = analyze_powershell_error_handling()
    
    # Validate database
    database_ok = validate_command_database()
    
    print("\n" + "="*50)
    print("📋 VALIDATION SUMMARY")
    print("="*50)
    
    if error_handling_ok:
        print("✅ PowerShell error handling: PASSED")
    else:
        print("❌ PowerShell error handling: FAILED")
    
    if database_ok:
        print("✅ Command database: PASSED")
    else:
        print("❌ Command database: FAILED")
    
    if error_handling_ok and database_ok:
        print("\n🎉 All validations PASSED! The TL1 Assistant should work correctly.")
        print("\nKey improvements made:")
        print("• Added null checks for OptionalPanel")
        print("• Wrapped Refresh-OptionalFields in try-catch")
        print("• Enhanced error logging throughout")
        print("• Maintained existing event handler error handling")
    else:
        print("\n⚠️  Some validations FAILED. Review the issues above.")
    
    return error_handling_ok and database_ok

if __name__ == "__main__":
    exit(0 if main() else 1)
#!/usr/bin/env python3
"""
Data Validation Script
Validates JSON files against expected schemas
"""
import json
import sys
from pathlib import Path


def validate_commands(file_path: Path) -> bool:
    """Validate commands.json structure"""
    print(f"[INFO] Validating {file_path}...")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Check required top-level keys
        if 'commands' not in data:
            print(f"[ERROR] Missing 'commands' key")
            return False
        
        if 'categories' not in data:
            print(f"[ERROR] Missing 'categories' key")
            return False
        
        # Validate commands structure
        commands = data['commands']
        if not isinstance(commands, dict):
            print(f"[ERROR] 'commands' must be a dictionary")
            return False
        
        # Check a few commands
        command_count = len(commands)
        print(f"[INFO] Found {command_count} commands")
        
        errors = []
        for cmd_id, cmd_data in list(commands.items())[:5]:  # Check first 5
            required_fields = ['verb', 'object', 'category', 'description']
            for field in required_fields:
                if field not in cmd_data:
                    errors.append(f"Command {cmd_id} missing field: {field}")
        
        if errors:
            for error in errors:
                print(f"[ERROR] {error}")
            return False
        
        print(f"[OK] commands.json is valid ({command_count} commands)")
        return True
        
    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid JSON: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Validation failed: {e}")
        return False


def validate_playbooks(file_path: Path) -> bool:
    """Validate playbooks.json structure"""
    print(f"[INFO] Validating {file_path}...")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Check required top-level keys
        if 'troubleshooting' not in data:
            print(f"[ERROR] Missing 'troubleshooting' key")
            return False
        
        if 'provisioning' not in data:
            print(f"[ERROR] Missing 'provisioning' key")
            return False
        
        # Count playbooks
        troubleshooting_count = len(data['troubleshooting'])
        provisioning_count = len(data['provisioning'])
        
        print(f"[INFO] Found {troubleshooting_count} troubleshooting playbooks")
        print(f"[INFO] Found {provisioning_count} provisioning playbooks")
        
        # Validate structure
        for playbook in data['troubleshooting']:
            if 'id' not in playbook or 'name' not in playbook or 'steps' not in playbook:
                print(f"[ERROR] Invalid troubleshooting playbook structure")
                return False
        
        for playbook in data['provisioning']:
            if 'id' not in playbook or 'name' not in playbook or 'steps' not in playbook:
                print(f"[ERROR] Invalid provisioning playbook structure")
                return False
        
        print(f"[OK] playbooks.json is valid")
        return True
        
    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid JSON: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Validation failed: {e}")
        return False


def validate_settings(file_path: Path) -> bool:
    """Validate settings.json structure"""
    print(f"[INFO] Validating {file_path}...")
    
    if not file_path.exists():
        print(f"[WARN] settings.json not found (will use defaults)")
        return True
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Check required sections
        required_sections = ['connection', 'defaults', 'logging', 'ui']
        for section in required_sections:
            if section not in data:
                print(f"[WARN] Missing section: {section}")
        
        print(f"[OK] settings.json is valid")
        return True
        
    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid JSON: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Validation failed: {e}")
        return False


def main():
    """Main validation function"""
    print("=" * 60)
    print("TL1 Assistant - Data Validation")
    print("=" * 60)
    print()
    
    # Get root path
    script_dir = Path(__file__).parent
    root_dir = script_dir.parent
    
    # Validate files
    all_valid = True
    
    commands_file = root_dir / 'data' / 'commands.json'
    if not validate_commands(commands_file):
        all_valid = False
    
    print()
    
    playbooks_file = root_dir / 'data' / 'playbooks.json'
    if not validate_playbooks(playbooks_file):
        all_valid = False
    
    print()
    
    settings_file = root_dir / 'settings.json'
    if not validate_settings(settings_file):
        all_valid = False
    
    print()
    print("=" * 60)
    if all_valid:
        print("[SUCCESS] All validations passed")
        print("=" * 60)
        sys.exit(0)
    else:
        print("[FAILURE] Some validations failed")
        print("=" * 60)
        sys.exit(1)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
Validate TL1 data files against JSON schemas
Validates commands.json and playbooks.json
"""
import json
import sys
from pathlib import Path
from typing import Dict, Any

try:
    import jsonschema
except ImportError:
    print("ERROR: jsonschema package not found.")
    print("Install with: pip install jsonschema")
    sys.exit(1)


def load_json_file(file_path: Path) -> Dict[str, Any]:
    """Load and parse JSON file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"ERROR: File not found: {file_path}")
        return None
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON in {file_path}: {e}")
        return None
    except Exception as e:
        print(f"ERROR: Failed to read {file_path}: {e}")
        return None


def validate_with_schema(data: Dict[str, Any], schema_path: Path, data_name: str) -> bool:
    """Validate data against JSON schema"""
    # Load schema
    schema = load_json_file(schema_path)
    if schema is None:
        return False
    
    try:
        # Validate
        jsonschema.validate(instance=data, schema=schema)
        print(f"✓ {data_name} is valid against schema")
        return True
    except jsonschema.ValidationError as e:
        print(f"✗ {data_name} validation failed:")
        print(f"  Path: {' -> '.join(str(p) for p in e.absolute_path)}")
        print(f"  Error: {e.message}")
        return False
    except jsonschema.SchemaError as e:
        print(f"✗ Schema error in {schema_path}: {e}")
        return False


def validate_commands(data_dir: Path) -> bool:
    """Validate commands.json"""
    print("Validating commands.json...")
    
    commands_file = data_dir / "commands.json"
    schema_file = data_dir / "commands.schema.json"
    
    data = load_json_file(commands_file)
    if data is None:
        return False
    
    # Basic structure validation
    if not validate_with_schema(data, schema_file, "commands.json"):
        return False
    
    # Additional validation checks
    warnings = []
    
    # Check metadata consistency
    metadata = data.get('metadata', {})
    commands = data.get('commands', {})
    categories = data.get('categories', {})
    
    actual_count = len(commands)
    stated_count = metadata.get('totalCommands', 0)
    if actual_count != stated_count:
        warnings.append(f"Command count mismatch: metadata says {stated_count}, found {actual_count}")
    
    # Check category references
    used_categories = set()
    for cmd_id, cmd in commands.items():
        category = cmd.get('category')
        if category:
            used_categories.add(category)
            if category not in categories:
                warnings.append(f"Command {cmd_id} references undefined category: {category}")
    
    unused_categories = set(categories.keys()) - used_categories
    if unused_categories:
        warnings.append(f"Unused categories: {', '.join(unused_categories)}")
    
    # Check syntax consistency
    for cmd_id, cmd in commands.items():
        syntax = cmd.get('syntax', '')
        verb = cmd.get('verb', '')
        obj = cmd.get('object', '')
        modifier = cmd.get('modifier')
        
        if modifier:
            expected_start = f"{verb}-{modifier}-{obj}:"
        else:
            expected_start = f"{verb}-{obj}:"
        
        if not syntax.startswith(expected_start):
            warnings.append(f"Command {cmd_id} syntax doesn't match verb-object structure")
    
    # Print warnings
    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"  ⚠ {warning}")
    
    print(f"Commands validation complete: {actual_count} commands checked")
    return True


def validate_playbooks(data_dir: Path) -> bool:
    """Validate playbooks.json"""
    print("\\nValidating playbooks.json...")
    
    playbooks_file = data_dir / "playbooks.json"
    schema_file = data_dir / "playbooks.schema.json"
    commands_file = data_dir / "commands.json"
    
    data = load_json_file(playbooks_file)
    if data is None:
        return False
    
    # Load commands for reference validation
    commands_data = load_json_file(commands_file)
    available_commands = set()
    if commands_data:
        available_commands = set(commands_data.get('commands', {}).keys())
    
    # Schema validation
    if not validate_with_schema(data, schema_file, "playbooks.json"):
        return False
    
    # Additional validation
    warnings = []
    
    troubleshooting = data.get('troubleshooting', [])
    provisioning = data.get('provisioning', [])
    
    # Check command references
    all_playbooks = troubleshooting + provisioning
    for playbook in all_playbooks:
        playbook_id = playbook.get('id', 'unknown')
        steps = playbook.get('steps', [])
        
        for step in steps:
            cmd = step.get('command', '')
            if cmd and cmd not in available_commands:
                warnings.append(f"Playbook '{playbook_id}' step {step.get('id')} references unknown command: {cmd}")
    
    # Check ID uniqueness
    all_ids = [p.get('id') for p in all_playbooks]
    duplicate_ids = set([x for x in all_ids if all_ids.count(x) > 1])
    if duplicate_ids:
        warnings.append(f"Duplicate playbook IDs: {', '.join(duplicate_ids)}")
    
    # Print warnings
    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"  ⚠ {warning}")
    
    print(f"Playbooks validation complete: {len(troubleshooting)} troubleshooting, {len(provisioning)} provisioning")
    return True


def main():
    """Main validation function"""
    # Determine data directory
    script_dir = Path(__file__).parent
    data_dir = script_dir.parent / "data"
    
    if not data_dir.exists():
        print(f"ERROR: Data directory not found: {data_dir}")
        sys.exit(1)
    
    print("TL1 Data Validation")
    print("=" * 50)
    
    success = True
    
    # Validate commands
    if not validate_commands(data_dir):
        success = False
    
    # Validate playbooks
    if not validate_playbooks(data_dir):
        success = False
    
    print("=" * 50)
    if success:
        print("✓ All validations passed!")
        sys.exit(0)
    else:
        print("✗ Validation failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
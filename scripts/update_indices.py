#!/usr/bin/env python3
"""
Index Manager for Platform Documentation
This script helps maintain and validate the documentation indices.
"""

import os
import json
import glob
from typing import Dict, List, Optional
import jsonschema

class PlatformIndexManager:
    def __init__(self, platform_path: str):
        """Initialize with platform directory path."""
        self.platform_path = platform_path
        self.commands_path = os.path.join(platform_path, 'commands')
        self.docs_path = os.path.join(platform_path, 'docs')
        
    def scan_commands(self) -> Dict:
        """Scan command files and build command index."""
        categories = {}
        
        # Scan each command category directory
        for category in ['alarms', 'configuration', 'maintenance', 
                        'monitoring', 'provisioning', 'security']:
            cat_path = os.path.join(self.commands_path, category)
            if not os.path.exists(cat_path):
                continue
                
            commands = []
            for cmd_file in glob.glob(os.path.join(cat_path, 'Command_*.pdf')):
                # Extract command name from filename
                cmd_name = os.path.basename(cmd_file).split('Command_')[1].split('.pdf')[0]
                commands.append({
                    'file': os.path.basename(cmd_file),
                    'command': cmd_name,
                    'schema_definition': f'schemas/commands/{cmd_name}.json',
                    'description': self._get_command_description(cmd_name)
                })
            
            if commands:
                categories[category] = {
                    'description': self._get_category_description(category),
                    'commands': commands
                }
        
        return {
            'version': '1.0',
            'platform': os.path.basename(self.platform_path),
            'categories': categories
        }
    
    def scan_docs(self) -> Dict:
        """Scan documentation files and build documentation index."""
        categories = {}
        
        # Scan each documentation category directory
        for category in ['installation', 'operations', 'reference', 'troubleshooting']:
            cat_path = os.path.join(self.docs_path, category)
            if not os.path.exists(cat_path):
                continue
                
            documents = []
            for doc_file in glob.glob(os.path.join(cat_path, '*.pdf')):
                doc_info = self._parse_doc_filename(doc_file)
                if doc_info:
                    documents.append(doc_info)
            
            if documents:
                categories[category] = {
                    'description': self._get_category_description(category),
                    'documents': documents
                }
        
        return {
            'version': '1.0',
            'platform': os.path.basename(self.platform_path),
            'categories': categories
        }
    
    def _parse_doc_filename(self, filepath: str) -> Optional[Dict]:
        """Parse document filename to extract metadata."""
        filename = os.path.basename(filepath)
        
        # Handle different document naming patterns
        if '__' in filename:
            parts = filename.split('__')
            doc_type = parts[0].strip()
            detail = parts[1].split('.pdf')[0].strip()
            
            # Extract ID if present (e.g., AJA-013, TAP-003)
            doc_id = None
            if ' - ' in detail:
                id_part = detail.split(' - ')[0]
                if '-' in id_part:
                    doc_id = id_part
                    detail = detail.split(' - ', 1)[1]
            
            return {
                'file': filename,
                'id': doc_id,
                'type': self._determine_doc_type(doc_type),
                'title': detail
            }
        return None
    
    def _determine_doc_type(self, prefix: str) -> str:
        """Determine document type from prefix."""
        type_map = {
            'Installation Practices': 'procedure',
            'Product Information': 'reference',
            'User Guide': 'guide'
        }
        for key, value in type_map.items():
            if key in prefix:
                return value
        return 'document'
    
    def _get_category_description(self, category: str) -> str:
        """Get description for a category."""
        descriptions = {
            'alarms': 'Alarm management commands',
            'configuration': 'System configuration commands',
            'maintenance': 'Maintenance operations',
            'monitoring': 'Status and performance monitoring',
            'provisioning': 'Service provisioning commands',
            'security': 'Security and user management',
            'installation': 'Installation guides and procedures',
            'operations': 'Operational procedures',
            'reference': 'Technical references and specifications',
            'troubleshooting': 'Problem diagnosis and resolution'
        }
        return descriptions.get(category, f'{category.title()} documentation')
    
    def _get_command_description(self, cmd_name: str) -> str:
        """Generate a human-readable description from command name."""
        # Split on hyphens and remove common prefixes
        parts = cmd_name.split('-')
        action = parts[0]
        target = '-'.join(parts[1:])
        
        # Map common actions to descriptions
        action_map = {
            'ALW': 'Allow',
            'CANC': 'Cancel',
            'DLT': 'Delete',
            'ED': 'Edit',
            'ENT': 'Enter',
            'INIT': 'Initialize',
            'OPR': 'Operate',
            'RTRV': 'Retrieve',
            'SET': 'Set'
        }
        
        action_desc = action_map.get(action, action)
        return f"{action_desc} {target.replace('-', ' ')}"
    
    def update_indices(self):
        """Update both command and documentation indices."""
        # Update command index
        cmd_index = self.scan_commands()
        cmd_index_path = os.path.join(self.commands_path, 'index.json')
        with open(cmd_index_path, 'w') as f:
            json.dump(cmd_index, f, indent=2)
        
        # Update documentation index
        doc_index = self.scan_docs()
        doc_index_path = os.path.join(self.docs_path, 'index.json')
        with open(doc_index_path, 'w') as f:
            json.dump(doc_index, f, indent=2)
        
        print(f"Updated indices in {self.platform_path}")

def main():
    # Get all platform directories
    platforms_root = os.path.join(os.path.dirname(__file__), '..', 'data', 'platforms')
    for platform_dir in glob.glob(os.path.join(platforms_root, '*')):
        if os.path.isdir(platform_dir) and not os.path.basename(platform_dir).startswith('.'):
            print(f"Processing platform: {os.path.basename(platform_dir)}")
            manager = PlatformIndexManager(platform_dir)
            manager.update_indices()

if __name__ == '__main__':
    main()
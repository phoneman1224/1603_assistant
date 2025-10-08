"""
Command catalog service
Handles loading, caching, and filtering of commands.json
"""
import json
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime

from ..logging_conf import get_logger
from .registry import registry


logger = get_logger(__name__)


class CommandCatalog:
    """Command catalog with caching and reload capabilities"""
    
    def __init__(self):
        self._commands: Dict = {}
        self._categories: Dict = {}
        self._last_load: Optional[datetime] = None
        self._file_mtime: Optional[float] = None
        self.load()
    
    def load(self, force: bool = False):
        """Load commands from JSON file with caching"""
        commands_file = registry.commands_json
        
        if not commands_file.exists():
            logger.error(f"Commands file not found: {commands_file}")
            return
        
        # Check if reload is needed
        current_mtime = commands_file.stat().st_mtime
        if not force and self._file_mtime == current_mtime:
            logger.debug("Commands already loaded, using cache")
            return
        
        try:
            with open(commands_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            self._commands = data.get('commands', {})
            self._categories = data.get('categories', {})
            self._last_load = datetime.now()
            self._file_mtime = current_mtime
            
            total = len(self._commands)
            logger.info(f"Loaded {total} commands from catalog")
            
        except Exception as e:
            logger.error(f"Failed to load commands: {e}")
            raise
    
    def reload(self):
        """Force reload commands"""
        logger.info("Reloading command catalog...")
        self.load(force=True)
    
    def get_all_commands(self, platform: Optional[str] = None) -> List[Dict]:
        """Get all commands, optionally filtered by platform"""
        commands = []
        
        for cmd_id, cmd_data in self._commands.items():
            # Filter by platform if specified
            if platform:
                # Handle both 'platform' and 'platforms' keys
                platforms = cmd_data.get('platforms', cmd_data.get('platform', []))
                if platform not in platforms:
                    continue
            
            command = {
                'id': cmd_id,
                'name': cmd_data.get('displayName', cmd_data.get('name', cmd_id)),
                'verb': cmd_data.get('verb', ''),
                'object': cmd_data.get('object', ''),
                'modifier': cmd_data.get('modifier', '') or '',
                'category': cmd_data.get('category', 'Other'),
                'platform': cmd_data.get('platforms', cmd_data.get('platform', [])),
                'description': cmd_data.get('description', ''),
                'required': cmd_data.get('requires', cmd_data.get('required', [])),
                'optional': cmd_data.get('optional', []),
                'paramSchema': cmd_data.get('paramSchema', {}),
                'examples': cmd_data.get('examples', []),
                'safety_level': cmd_data.get('safety_level', 'safe'),
                'service_affecting': cmd_data.get('service_affecting', False),
                'response_format': cmd_data.get('response_format', '')
            }
            commands.append(command)
        
        return sorted(commands, key=lambda x: x['name'])
    
    def get_command(self, cmd_id: str) -> Optional[Dict]:
        """Get a specific command by ID"""
        cmd_data = self._commands.get(cmd_id)
        if not cmd_data:
            return None
        
        return {
            'id': cmd_id,
            'name': cmd_data.get('displayName', cmd_data.get('name', cmd_id)),
            'verb': cmd_data.get('verb', ''),
            'object': cmd_data.get('object', ''),
            'modifier': cmd_data.get('modifier', '') or '',
            'category': cmd_data.get('category', 'Other'),
            'platform': cmd_data.get('platforms', cmd_data.get('platform', [])),
            'description': cmd_data.get('description', ''),
            'required': cmd_data.get('requires', cmd_data.get('required', [])),
            'optional': cmd_data.get('optional', []),
            'paramSchema': cmd_data.get('paramSchema', {}),
            'examples': cmd_data.get('examples', []),
            'safety_level': cmd_data.get('safety_level', 'safe'),
            'service_affecting': cmd_data.get('service_affecting', False),
            'response_format': cmd_data.get('response_format', '')
        }
    
    def get_categories(self, platform: Optional[str] = None) -> List[Dict]:
        """Get list of categories with command counts"""
        # Count commands per category
        counts = {}
        for cmd_data in self._commands.values():
            # Filter by platform if specified
            if platform:
                platforms = cmd_data.get('platforms', cmd_data.get('platform', []))
                if platform not in platforms:
                    continue
            
            category = cmd_data.get('category', 'Other')
            counts[category] = counts.get(category, 0) + 1
        
        # Build category list
        categories = []
        for cat_name, cat_data in self._categories.items():
            if cat_name in counts:
                categories.append({
                    'name': cat_name,
                    'description': cat_data.get('description', ''),
                    'icon': cat_data.get('icon', 'folder'),
                    'count': counts[cat_name]
                })
        
        return sorted(categories, key=lambda x: x['name'])


# Global instance
catalog = CommandCatalog()

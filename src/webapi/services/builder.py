"""
TL1 Command Builder Service
Builds TL1 command strings with lenient validation
"""
from typing import Dict, List, Optional, Tuple

from ..logging_conf import get_logger
from .catalog import catalog


logger = get_logger(__name__)


class TL1Builder:
    """TL1 command builder with lenient validation"""
    
    def build_command(
        self,
        cmd_id: str,
        tid: str = "",
        aid: str = "",
        ctag: str = "1",
        optional: Optional[Dict[str, any]] = None
    ) -> Tuple[str, List[str]]:
        """
        Build TL1 command string
        
        Returns:
            Tuple of (command_string, warnings)
        """
        warnings = []
        
        # Get command spec
        cmd_spec = catalog.get_command(cmd_id)
        if not cmd_spec:
            raise ValueError(f"Command not found: {cmd_id}")
        
        # Build verb-object portion
        verb = cmd_spec['verb']
        obj = cmd_spec['object']
        modifier = cmd_spec.get('modifier', '')
        
        if modifier:
            verb_part = f"{verb}-{modifier}-{obj}"
        else:
            verb_part = f"{verb}-{obj}"
        
        # Handle TID (vacant if empty)
        tid_part = tid.strip() if tid else ""
        
        # Handle AID (vacant if empty)
        aid_part = aid.strip() if aid else ""
        
        # CTAG is required
        if not ctag:
            ctag = "1"
            warnings.append("CTAG is required, defaulting to '1'")
        
        # Build parameters from optional dict
        params_list = []
        if optional:
            for key, value in optional.items():
                if value is not None and str(value).strip():
                    params_list.append(f"{key}={value}")
        
        params_part = ",".join(params_list) if params_list else ""
        
        # Build full command: VERB-MODIFIER-OBJECT:TID:AID:CTAG::PARAMS;
        command = f"{verb_part}:{tid_part}:{aid_part}:{ctag}::{params_part};"
        
        # Validate command structure
        validation_warnings = self._validate(command, cmd_spec)
        warnings.extend(validation_warnings)
        
        return command, warnings
    
    def _validate(self, command: str, cmd_spec: Dict) -> List[str]:
        """
        Lenient validation - returns warnings, doesn't fail
        """
        warnings = []
        
        # Check for proper termination
        if not command.endswith(';'):
            warnings.append("Command should end with semicolon")
        
        # Check for double colons before parameters
        if '::' not in command:
            warnings.append("Command should have '::' before parameters")
        
        # Check for service-affecting operations
        if cmd_spec.get('service_affecting', False):
            warnings.append("WARNING: This command is service-affecting!")
        
        # Check safety level
        safety = cmd_spec.get('safety_level', 'safe')
        if safety in ['caution', 'dangerous']:
            warnings.append(f"CAUTION: Safety level is '{safety}'")
        
        return warnings
    
    def preview_command(
        self,
        verb: str,
        obj: str,
        modifier: str = "",
        tid: str = "",
        aid: str = "",
        ctag: str = "1",
        params: str = ""
    ) -> Tuple[str, List[str]]:
        """
        Build command from raw components (for manual entry)
        """
        warnings = []
        
        # Build verb-object portion
        if modifier:
            verb_part = f"{verb}-{modifier}-{obj}"
        else:
            verb_part = f"{verb}-{obj}"
        
        # Handle vacant parameters
        tid_part = tid.strip() if tid else ""
        aid_part = aid.strip() if aid else ""
        
        if not ctag:
            ctag = "1"
            warnings.append("CTAG is required, defaulting to '1'")
        
        params_part = params.strip() if params else ""
        
        # Build full command
        command = f"{verb_part}:{tid_part}:{aid_part}:{ctag}::{params_part};"
        
        return command, warnings


# Global instance
builder = TL1Builder()

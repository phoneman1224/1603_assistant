"""
Playbook Runner Service
Executes troubleshooting and provisioning workflows
"""
import json
import asyncio
from typing import Dict, List, Optional, AsyncGenerator
from pathlib import Path

from ..logging_conf import get_logger, log_tl1
from .registry import registry
from .builder import builder


logger = get_logger(__name__)


class PlaybookRunner:
    """Async playbook executor"""
    
    def __init__(self):
        self._playbooks = {}
        self.load_playbooks()
    
    def load_playbooks(self):
        """Load playbooks from JSON"""
        playbooks_file = registry.playbooks_json
        
        if not playbooks_file.exists():
            logger.error(f"Playbooks file not found: {playbooks_file}")
            return
        
        try:
            with open(playbooks_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            self._playbooks = {
                'troubleshooting': data.get('troubleshooting', []),
                'provisioning': data.get('provisioning', [])
            }
            
            total = len(self._playbooks['troubleshooting']) + len(self._playbooks['provisioning'])
            logger.info(f"Loaded {total} playbooks")
            
        except Exception as e:
            logger.error(f"Failed to load playbooks: {e}")
    
    def get_playbook(self, flow_name: str, section: str = None) -> Optional[Dict]:
        """Get a playbook by name"""
        # Search in troubleshooting
        for pb in self._playbooks.get('troubleshooting', []):
            if pb.get('id') == flow_name or pb.get('name') == flow_name:
                return pb
        
        # Search in provisioning
        for pb in self._playbooks.get('provisioning', []):
            if pb.get('id') == flow_name or pb.get('name') == flow_name:
                return pb
        
        return None
    
    def get_all_playbooks(self) -> Dict:
        """Get all playbooks organized by section"""
        return {
            'troubleshooting': self._playbooks.get('troubleshooting', []),
            'provisioning': self._playbooks.get('provisioning', [])
        }
    
    async def run_troubleshooting(
        self,
        flow_name: str,
        tid: str = "",
        aid: str = "",
        ctag_start: int = 1,
        sender_func=None
    ) -> AsyncGenerator[Dict, None]:
        """
        Run a troubleshooting playbook asynchronously
        Yields progress updates for each step
        """
        playbook = self.get_playbook(flow_name)
        if not playbook:
            yield {
                'type': 'error',
                'message': f"Playbook not found: {flow_name}"
            }
            return
        
        log_tl1('TROUBLESHOOT', f"Starting playbook: {playbook.get('name')}")
        
        yield {
            'type': 'start',
            'playbook': playbook.get('name'),
            'description': playbook.get('description'),
            'total_steps': len(playbook.get('steps', []))
        }
        
        ctag = ctag_start
        
        for step in playbook.get('steps', []):
            step_id = step.get('id')
            step_name = step.get('name')
            command_template = step.get('command')
            params = step.get('params', {})
            
            # Replace variables
            step_tid = params.get('TID', '').replace('$TID', tid)
            step_aid = params.get('AID', '').replace('$AID', aid)
            step_ctag = str(ctag)
            
            # Build command (simplified for troubleshooting)
            command = f"{command_template}:{step_tid}:{step_aid}:{step_ctag}::;"
            
            log_tl1('SEND', command)
            
            yield {
                'type': 'step',
                'step_id': step_id,
                'step_name': step_name,
                'command': command,
                'ctag': ctag
            }
            
            # Send command if sender function provided
            if sender_func:
                try:
                    response = await sender_func(command)
                    log_tl1('RECV', response.get('response', 'No response'))
                    
                    yield {
                        'type': 'response',
                        'step_id': step_id,
                        'response': response
                    }
                    
                    # Check expected response
                    expected = step.get('expectedResponse', 'COMPLD')
                    if expected in response.get('response', ''):
                        yield {
                            'type': 'success',
                            'step_id': step_id,
                            'message': f"Step {step_id} completed successfully"
                        }
                    else:
                        on_error = step.get('onError', 'continue')
                        yield {
                            'type': 'warning',
                            'step_id': step_id,
                            'message': f"Step {step_id} did not return expected response"
                        }
                        if on_error == 'abort':
                            break
                
                except Exception as e:
                    yield {
                        'type': 'error',
                        'step_id': step_id,
                        'message': f"Step {step_id} failed: {str(e)}"
                    }
                    on_error = step.get('onError', 'continue')
                    if on_error == 'abort':
                        break
            
            # Increment CTAG
            ctag += 1
            
            # Small delay between steps
            await asyncio.sleep(0.5)
        
        log_tl1('SUMMARY', f"Playbook completed: {playbook.get('name')}")
        
        yield {
            'type': 'complete',
            'message': 'Troubleshooting playbook completed'
        }
    
    async def run_provisioning(
        self,
        flow_name: str,
        step_state: Dict,
        tid: str = "",
        ctag: int = 1,
        send: bool = False,
        sender_func=None
    ) -> Dict:
        """
        Run a provisioning playbook with user-provided state
        Returns preview or result
        """
        playbook = self.get_playbook(flow_name)
        if not playbook:
            return {
                'status': 'error',
                'message': f"Playbook not found: {flow_name}"
            }
        
        # Find the final step (with preview=true)
        final_step = None
        for step in playbook.get('steps', []):
            if step.get('preview'):
                final_step = step
                break
        
        if not final_step:
            return {
                'status': 'error',
                'message': 'No preview step found in playbook'
            }
        
        # Build command from step state
        command_type = final_step.get('command')
        params = final_step.get('params', {})
        
        # Replace variables
        aid = step_state.get('AID', '')
        optional_params = {}
        
        for key, value in step_state.items():
            if key not in ['AID', 'TID', 'CTAG']:
                optional_params[key] = value
        
        # Build command using builder
        try:
            # This is a simplified version - in real implementation,
            # we'd need to map command_type to cmd_id
            command = f"{command_type}:{tid}:{aid}:{ctag}::"
            
            # Add optional parameters
            if optional_params:
                params_str = ",".join([f"{k}={v}" for k, v in optional_params.items() if v])
                command += params_str
            
            command += ";"
            
            result = {
                'status': 'preview',
                'command': command,
                'params': step_state
            }
            
            # Send if requested
            if send and sender_func:
                log_tl1('SEND', command)
                response = await sender_func(command)
                log_tl1('RECV', response.get('response', 'No response'))
                
                result['status'] = 'sent'
                result['response'] = response
            
            return result
            
        except Exception as e:
            return {
                'status': 'error',
                'message': str(e)
            }


# Global instance
runner = PlaybookRunner()

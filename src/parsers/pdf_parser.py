#!/usr/bin/env python3
"""
PDF Parser for Command Documentation
Extracts structured data from PDF command documentation.
"""

import os
import json
import re
from typing import Dict, List, Optional, Tuple
import pdfplumber  # You'll need to add this to requirements.txt

class CommandDocParser:
    def __init__(self):
        """Initialize parser with common patterns."""
        self.patterns = {
            'command_name': r'^([A-Z-]+)(?=\s|$)',
            'parameters': r'Parameter\s+Description\s+[-]+\s+(.*?)(?=\n\n)',
            'syntax': r'Syntax:\s*(.*?)(?=\n\n)',
            'description': r'Description:\s*(.*?)(?=\n\n)',
            'response': r'Response:\s*(.*?)(?=\n\n)',
            'example': r'Example:\s*(.*?)(?=\n\n)'
        }
        
    def parse_command_doc(self, pdf_path: str) -> Dict:
        """Parse a command documentation PDF and extract structured data."""
        try:
            with pdfplumber.open(pdf_path) as pdf:
                text = '\n'.join(page.extract_text() for page in pdf.pages)
                
            # Extract basic command info
            command_info = {
                'name': self._extract_command_name(text),
                'syntax': self._extract_syntax(text),
                'description': self._extract_description(text),
                'parameters': self._extract_parameters(text),
                'response_format': self._extract_response_format(text),
                'examples': self._extract_examples(text)
            }
            
            # Extract any related references
            command_info.update(self._extract_references(text))
            
            return command_info
            
        except Exception as e:
            return {
                'error': f'Failed to parse PDF: {str(e)}',
                'file': pdf_path
            }
    
    def _extract_command_name(self, text: str) -> str:
        """Extract the command name from the document."""
        match = re.search(self.patterns['command_name'], text)
        return match.group(1) if match else ''
    
    def _extract_syntax(self, text: str) -> str:
        """Extract command syntax."""
        match = re.search(self.patterns['syntax'], text, re.DOTALL)
        if match:
            syntax = match.group(1).strip()
            # Clean up common formatting issues
            syntax = re.sub(r'\s+', ' ', syntax)
            return syntax
        return ''
    
    def _extract_description(self, text: str) -> str:
        """Extract command description."""
        match = re.search(self.patterns['description'], text, re.DOTALL)
        if match:
            desc = match.group(1).strip()
            # Clean up and normalize
            desc = re.sub(r'\s+', ' ', desc)
            return desc
        return ''
    
    def _extract_parameters(self, text: str) -> List[Dict]:
        """Extract and structure parameter information."""
        params = []
        match = re.search(self.patterns['parameters'], text, re.DOTALL)
        if match:
            param_text = match.group(1)
            # Split into parameter blocks
            blocks = re.split(r'\n(?=[A-Z])', param_text)
            for block in blocks:
                if ':' in block:
                    name, desc = block.split(':', 1)
                    params.append({
                        'name': name.strip(),
                        'description': desc.strip(),
                        'required': 'required' in desc.lower(),
                        'type': self._infer_parameter_type(desc)
                    })
        return params
    
    def _extract_response_format(self, text: str) -> Dict:
        """Extract response format information."""
        match = re.search(self.patterns['response'], text, re.DOTALL)
        if match:
            resp_text = match.group(1)
            # Parse completion codes and output format
            return {
                'completion_codes': self._extract_completion_codes(resp_text),
                'output_format': self._parse_output_format(resp_text)
            }
        return {}
    
    def _extract_examples(self, text: str) -> List[Dict]:
        """Extract command examples."""
        examples = []
        match = re.search(self.patterns['example'], text, re.DOTALL)
        if match:
            example_text = match.group(1)
            # Split into input/response pairs
            pairs = re.split(r'\n(?=Input:|Response:)', example_text)
            current_example = {}
            
            for pair in pairs:
                if pair.startswith('Input:'):
                    if current_example and 'input' in current_example:
                        examples.append(current_example)
                        current_example = {}
                    current_example['input'] = pair.replace('Input:', '').strip()
                elif pair.startswith('Response:'):
                    current_example['response'] = pair.replace('Response:', '').strip()
                    
            if current_example:
                examples.append(current_example)
                
        return examples
    
    def _extract_references(self, text: str) -> Dict:
        """Extract references to related documents."""
        references = {
            'dlps': [],
            'taps': [],
            'related_commands': []
        }
        
        # Look for DLP references
        dlp_matches = re.finditer(r'DLP-(\d{3})', text)
        references['dlps'] = [f"DLP-{m.group(1)}" for m in dlp_matches]
        
        # Look for TAP references
        tap_matches = re.finditer(r'TAP-(\d{3})', text)
        references['taps'] = [f"TAP-{m.group(1)}" for m in tap_matches]
        
        # Look for related command references
        cmd_matches = re.finditer(r'(?:see|refer to|related)\s+([A-Z-]+)(?=\s|$)', text)
        references['related_commands'] = list(set(m.group(1) for m in cmd_matches))
        
        return references
    
    def _infer_parameter_type(self, description: str) -> str:
        """Infer parameter type from description."""
        desc_lower = description.lower()
        if any(word in desc_lower for word in ['integer', 'number', 'numeric']):
            return 'integer'
        elif any(word in desc_lower for word in ['decimal', 'float']):
            return 'number'
        elif any(word in desc_lower for word in ['true', 'false', 'boolean']):
            return 'boolean'
        elif any(word in desc_lower for word in ['date', 'time']):
            return 'datetime'
        elif 'list of' in desc_lower or 'array of' in desc_lower:
            return 'array'
        return 'string'
    
    def _extract_completion_codes(self, response_text: str) -> List[Dict]:
        """Extract completion codes and their meanings."""
        codes = []
        code_matches = re.finditer(r'(COMPLD|DENY|DELAY|PRTL)\s*[-:]*\s*([^\n]+)', 
                                 response_text)
        for match in code_matches:
            codes.append({
                'code': match.group(1),
                'description': match.group(2).strip()
            })
        return codes
    
    def _parse_output_format(self, response_text: str) -> Dict:
        """Parse the output format specification."""
        format_info = {
            'columns': [],
            'format': ''
        }
        
        # Look for column definitions
        col_match = re.search(r'Output Format:?\s*(.*?)(?=\n\n|\Z)', 
                            response_text, re.DOTALL)
        if col_match:
            format_text = col_match.group(1)
            # Parse column names
            cols = re.findall(r'"([^"]+)"', format_text)
            if cols:
                format_info['columns'] = cols
            format_info['format'] = format_text.strip()
            
        return format_info

def main():
    """Example usage of the command parser."""
    parser = CommandDocParser()
    
    # Parse a sample command document
    sample_path = '/workspaces/1603_assistant/data/platforms/1603_SM/commands/alarms/Command_ALW-LPBK-T1.pdf'
    if os.path.exists(sample_path):
        result = parser.parse_command_doc(sample_path)
        print(json.dumps(result, indent=2))
    else:
        print("Sample command document not found")

if __name__ == '__main__':
    main()
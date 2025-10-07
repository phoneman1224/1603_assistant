#!/usr/bin/env python3
"""
Extract TL1 command information from PDF documentation
Creates raw extraction files from PDF files for manual review and catalog creation

NOTE: This script produces raw extractions for manual review.
The main system now uses the structured data/commands.json catalog.
Use this script only when adding new PDFs or updating existing ones.
"""

import os
import json
import re
import pdfplumber
from pathlib import Path

def extract_command_info(pdf_path):
    """Extract structured command information from PDF."""
    try:
        with pdfplumber.open(pdf_path) as pdf:
            all_text = ""
            for page in pdf.pages:
                text = page.extract_text()
                if text:
                    all_text += text + "\n"
        
        # Extract command info using patterns
        info = {
            "source_file": pdf_path.split('/')[-1],
            "command_code": "",
            "description": "",
            "syntax": "",
            "parameters": {},
            "restrictions": "",
            "function": "",
            "response_format": "",
            "examples": [],
            "category": "",
            "subcategory": "",
            "safety_level": "safe",
            "service_affecting": False
        }
        
        # Extract command name
        cmd_match = re.search(r'Command:\s*([A-Z][A-Z0-9-]+)', all_text)
        if cmd_match:
            info["command_code"] = cmd_match.group(1)
        
        # Extract message category
        cat_match = re.search(r'Message category:\s*([^\n]+)', all_text)
        if cat_match:
            info["category"] = cat_match.group(1).strip()
        
        # Extract application
        app_match = re.search(r'Application:\s*([^\n]+)', all_text)
        if app_match:
            info["subcategory"] = app_match.group(1).strip()
        
        # Extract definition/description
        def_match = re.search(r'Definition:\s*\n([^.]+\.)', all_text)
        if def_match:
            info["description"] = def_match.group(1).strip()
        
        # Extract function
        func_match = re.search(r'Function:\s*\n([^C]+?)(?=Command Format:|Restrictions:)', all_text, re.DOTALL)
        if func_match:
            info["function"] = func_match.group(1).strip()
        
        # Extract command format/syntax
        format_match = re.search(r'Command Format:\s*\n([^;]+;)', all_text)
        if format_match:
            info["syntax"] = format_match.group(1).strip()
        
        # Extract restrictions
        restr_match = re.search(r'Restrictions:\s*\n([^F]+?)(?=Function:|Command Format:|Command Parameters)', all_text, re.DOTALL)
        if restr_match:
            info["restrictions"] = restr_match.group(1).strip()
        
        # Extract parameters - look for parameter table
        param_section = re.search(r'Command Parameters\s+(.*?)(?=Response Format:|Error Codes:|Normal Response:|$)', all_text, re.DOTALL)
        if param_section:
            param_text = param_section.group(1)
            # Parse parameter lines
            param_lines = param_text.split('\n')
            current_param = None
            for line in param_lines:
                line = line.strip()
                if line and not line.startswith('PARAMETER') and line != 'EXPLANATION':
                    # Check if this is a parameter name
                    param_match = re.match(r'\[([^\]]+)\]', line)
                    if param_match:
                        current_param = param_match.group(1)
                        # Get description from rest of line
                        desc_part = line[param_match.end():].strip()
                        info["parameters"][current_param] = desc_part
                    elif current_param and line and not re.match(r'\[', line):
                        # Continue description on next line
                        info["parameters"][current_param] += " " + line
        
        # Extract response format
        resp_match = re.search(r'Normal Response[^:]*:\s*(.*?)(?=Error Response:|Error Codes:|$)', all_text, re.DOTALL)
        if resp_match:
            info["response_format"] = resp_match.group(1).strip()[:500]  # Limit length
        
        # Determine safety level based on command name and description
        dangerous_keywords = ['dlt', 'delete', 'rmv', 'remove', 'rst', 'reset', 'act-user', 'canc-user']
        service_affecting_keywords = ['ent-crs', 'dlt-crs', 'ed-', 'set-attr']
        
        cmd_lower = info["command_code"].lower()
        desc_lower = info["description"].lower()
        
        if any(keyword in cmd_lower for keyword in dangerous_keywords):
            info["safety_level"] = "caution"
        
        if any(keyword in cmd_lower for keyword in service_affecting_keywords):
            info["service_affecting"] = True
        
        return info
        
    except Exception as e:
        return {"error": str(e), "source_file": pdf_path.split('/')[-1]}

def process_platform_commands(platform_path):
    """Process all command PDFs for a platform."""
    commands_by_category = {}
    
    # Find all PDF files in command directories
    for root, dirs, files in os.walk(platform_path):
        for file in files:
            if file.endswith('.pdf') and 'Command_' in file:
                pdf_path = os.path.join(root, file)
                print(f"Processing: {file}")
                
                cmd_info = extract_command_info(pdf_path)
                
                if "error" in cmd_info:
                    print(f"  ERROR: {cmd_info['error']}")
                    continue
                
                if not cmd_info["command_code"]:
                    print(f"  SKIP: No command code found")
                    continue
                
                # Determine category from file path
                if not cmd_info["category"]:
                    path_parts = pdf_path.split('/')
                    if len(path_parts) > 2:
                        cmd_info["category"] = path_parts[-2].title()  # Use directory name
                
                category = cmd_info["category"] or "General"
                
                if category not in commands_by_category:
                    commands_by_category[category] = []
                
                commands_by_category[category].append(cmd_info)
                print(f"  SUCCESS: {cmd_info['command_code']} -> {category}")
    
    return commands_by_category

def main():
    """Main extraction process."""
    repo_root = Path(__file__).parent.parent
    platforms_dir = repo_root / "data" / "platforms"
    output_dir = repo_root / "data" / "raw_pdf_extractions"
    
    # Create output directory
    output_dir.mkdir(exist_ok=True)
    
    all_platforms = {}
    
    # Process each platform
    for platform_dir in platforms_dir.iterdir():
        if platform_dir.is_dir():
            platform_name = platform_dir.name
            print(f"\n{'='*60}")
            print(f"PROCESSING PLATFORM: {platform_name}")
            print('='*60)
            
            commands_path = platform_dir / "commands"
            if commands_path.exists():
                platform_commands = process_platform_commands(str(commands_path))
                all_platforms[platform_name] = platform_commands
                
                # Save platform-specific file
                platform_output = output_dir / f"{platform_name}_commands.json"
                with open(platform_output, 'w', encoding='utf-8') as f:
                    json.dump(platform_commands, f, indent=2, ensure_ascii=False)
                
                print(f"\nPlatform {platform_name} complete:")
                for category, commands in platform_commands.items():
                    print(f"  {category}: {len(commands)} commands")
    
    # Save combined file
    combined_output = output_dir / "all_platforms_commands.json"
    with open(combined_output, 'w', encoding='utf-8') as f:
        json.dump(all_platforms, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*60}")
    print("EXTRACTION COMPLETE")
    print('='*60)
    print(f"Output saved to: {output_dir}")
    
    # Print summary
    total_commands = 0
    for platform, categories in all_platforms.items():
        platform_total = sum(len(commands) for commands in categories.values())
        total_commands += platform_total
        print(f"{platform}: {platform_total} commands")
    
    print(f"TOTAL COMMANDS EXTRACTED: {total_commands}")

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""
Update documentation indices for all platforms.
"""

import os
import json
import glob
from pathlib import Path

def update_platform_indices():
    """Update indices for all platforms."""
    platforms_dir = Path("data/platforms")
    
    for platform_dir in platforms_dir.glob("*/"):
        if platform_dir.is_dir():
            print(f"Updating indices for {platform_dir.name}")
            
            # Update command index
            update_command_index(platform_dir)
            
            # Update documentation index
            update_doc_index(platform_dir)

def update_command_index(platform_dir):
    """Update command index for a platform."""
    commands_dir = platform_dir / "commands"
    if not commands_dir.exists():
        return
        
    index = {
        "version": "1.0",
        "platform": platform_dir.name,
        "categories": {}
    }
    
    for category_dir in commands_dir.glob("*/"):
        if category_dir.is_dir() and category_dir.name != "__pycache__":
            commands = []
            for pdf_file in category_dir.glob("*.pdf"):
                command_name = pdf_file.stem.replace("Command_ ", "")
                commands.append({
                    "file": pdf_file.name,
                    "command": command_name,
                    "description": f"Command: {command_name}"
                })
            
            if commands:
                index["categories"][category_dir.name] = {
                    "description": f"{category_dir.name.title()} commands",
                    "commands": commands
                }
    
    # Write index
    index_file = commands_dir / "index.json"
    with open(index_file, 'w') as f:
        json.dump(index, f, indent=2)

def update_doc_index(platform_dir):
    """Update documentation index for a platform."""
    docs_dir = platform_dir / "docs"
    if not docs_dir.exists():
        return
        
    index = {
        "version": "1.0",
        "platform": platform_dir.name,
        "categories": {}
    }
    
    for category_dir in docs_dir.glob("*/"):
        if category_dir.is_dir() and category_dir.name != "__pycache__":
            documents = []
            for doc_file in category_dir.glob("*.pdf"):
                documents.append({
                    "file": doc_file.name,
                    "title": doc_file.stem,
                    "type": "document"
                })
            
            if documents:
                index["categories"][category_dir.name] = {
                    "description": f"{category_dir.name.title()} documentation",
                    "documents": documents
                }
    
    # Write index
    index_file = docs_dir / "index.json"
    with open(index_file, 'w') as f:
        json.dump(index, f, indent=2)

if __name__ == "__main__":
    update_platform_indices()
    print("Indices updated successfully!")
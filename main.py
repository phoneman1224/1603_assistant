#!/usr/bin/env python3
"""
TL1 Assistant - Main Entry Point
Simple startup script that handles imports correctly
"""
import sys
import os
from pathlib import Path

# Add the src directory to Python path
root_dir = Path(__file__).parent
src_dir = root_dir / "src"
sys.path.insert(0, str(src_dir))

# Now we can import the app
try:
    from webapi.app import app
    import uvicorn
    
    if __name__ == "__main__":
        print("🚀 Starting TL1 Assistant Web Server...")
        print("🌐 Web Interface: http://localhost:8000")
        print("📡 API Documentation: http://localhost:8000/docs")
        print("Press Ctrl+C to stop")
        print("")
        
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=8000,
            log_level="info"
        )
        
except ImportError as e:
    print(f"❌ Import Error: {e}")
    print("Make sure you're running from the TL1 Assistant root directory")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error starting server: {e}")
    sys.exit(1)
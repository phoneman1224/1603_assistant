#!/bin/bash

echo "========================================"
echo "   TL1 Assistant - Web GUI Launcher"
echo "========================================"
echo

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo "❌ Python not found. Please install Python 3.7+ first."
        echo
        echo "Install with: sudo apt install python3  (Ubuntu/Debian)"
        echo "            : brew install python3      (macOS)"
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

echo "✅ Python found ($PYTHON_CMD)"
echo "🚀 Starting TL1 Assistant Web GUI..."
echo

# Make sure we're in the right directory
cd "$(dirname "$0")"

# Run the web GUI
$PYTHON_CMD tl1_web_gui.py

echo
echo "Press Enter to exit..."
read
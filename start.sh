#!/bin/bash
# TL1 Assistant - Simple Startup Script
# This script starts the TL1 Assistant with minimal setup

echo "=========================================="
echo "    TL1 Assistant - Network Manager"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: Please run this script from the TL1 Assistant directory"
    exit 1
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is required but not installed"
    exit 1
fi

echo "🔧 Setting up Python environment..."

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install requirements
echo "📦 Installing Python dependencies..."
pip install -q -r requirements.txt

# Check if Node.js is available for web interface
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    echo "🌐 Setting up web interface..."
    cd webui
    if [ ! -d "node_modules" ]; then
        npm install -q
    fi
    
    # Build the frontend
    npm run build -q
    cd ..
    
    echo ""
    echo "✅ Starting TL1 Assistant with Web Interface..."
    echo ""
    echo "🌐 Web Interface: http://localhost:8000"
    echo "📡 API Endpoints: http://localhost:8000/docs"
    echo ""
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Start the backend (which serves the frontend)
    python main.py
else
    echo ""
    echo "⚠️  Node.js not found - starting API-only mode"
    echo ""
    echo "📡 API Server: http://localhost:8000"
    echo "📖 API Documentation: http://localhost:8000/docs"
    echo ""
    echo "To get the full web interface, install Node.js from https://nodejs.org"
    echo ""
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Start the backend only
    python main.py
fi
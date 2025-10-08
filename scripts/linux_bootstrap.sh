#!/bin/bash
# Linux bootstrap script for TL1 Assistant

set -e

echo "================================================"
echo "TL1 Assistant - Linux Bootstrap"
echo "================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    echo "[ERROR] Please run this script from the root of the 1603_assistant repository"
    exit 1
fi

# Step 1: Check Python
echo "[1/6] Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "[OK] Python found: $PYTHON_VERSION"
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version)
    echo "[OK] Python found: $PYTHON_VERSION"
    PYTHON_CMD="python"
else
    echo "[ERROR] Python not found. Please install Python 3.8 or higher."
    exit 1
fi

# Step 2: Create/activate virtual environment
echo ""
echo "[2/6] Setting up Python virtual environment..."
if [ ! -d ".venv" ]; then
    echo "[INFO] Creating virtual environment..."
    $PYTHON_CMD -m venv .venv
    echo "[OK] Virtual environment created"
else
    echo "[INFO] Virtual environment already exists"
fi

# Activate virtual environment
echo "[INFO] Activating virtual environment..."
source .venv/bin/activate

# Step 3: Install Python dependencies
echo ""
echo "[3/6] Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
echo "[OK] Python dependencies installed"

# Step 4: Check Node.js and install frontend dependencies
echo ""
echo "[4/6] Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "[OK] Node.js found: $NODE_VERSION"
    
    echo "[INFO] Installing frontend dependencies..."
    cd webui
    npm install
    cd ..
    echo "[OK] Frontend dependencies installed"
else
    echo "[WARNING] Node.js not found. Web UI will not be available."
    echo "Install Node.js 18+ to use the web interface."
fi

# Step 5: Validate data files
echo ""
echo "[5/6] Validating data files..."
if [ -f "scripts/validate_data.py" ]; then
    python scripts/validate_data.py
    echo "[OK] Data validation complete"
else
    echo "[WARNING] Data validation script not found"
fi

# Step 6: Launch application
echo ""
echo "[6/6] Launching application..."

# Check if user wants to launch specific mode
if [ "$1" == "--web-only" ]; then
    echo "[INFO] Starting web interface only..."
    echo "Backend: http://127.0.0.1:8000"
    echo "Frontend: http://127.0.0.1:5173"
    echo ""
    echo "Starting FastAPI backend..."
    python src/webapi/app.py &
    BACKEND_PID=$!
    
    echo "Starting Vite frontend..."
    cd webui && npm run dev &
    FRONTEND_PID=$!
    
    echo ""
    echo "Application started! Open http://127.0.0.1:5173 in your browser"
    echo "Press Ctrl+C to stop both servers"
    
    # Wait for user interrupt
    trap "echo 'Stopping servers...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit 0" INT
    wait
else
    echo "[INFO] Setup complete!"
    echo ""
    echo "To start the web interface:"
    echo "  ./scripts/linux_bootstrap.sh --web-only"
    echo ""
    echo "To start backend only:"
    echo "  source .venv/bin/activate"
    echo "  python src/webapi/app.py"
    echo ""
    echo "To start frontend only:"
    echo "  cd webui && npm run dev"
    echo ""
    echo "Backend will be available at: http://127.0.0.1:8000"
    echo "Frontend will be available at: http://127.0.0.1:5173"
fi
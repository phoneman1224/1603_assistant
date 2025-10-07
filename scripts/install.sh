#!/bin/bash
# TL1 Assistant Installation Script for Linux/macOS
# Version 1.0.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation configuration
INSTALL_DIR="$HOME/TL1Assistant"
APP_NAME="TL1 Assistant"
PYTHON_MIN_VERSION="3.6"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}   TL1 Assistant Installation Script  ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to compare version numbers
version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Check if Python is installed
print_status "Checking Python installation..."
if command_exists python3; then
    PYTHON_CMD="python3"
elif command_exists python; then
    PYTHON_CMD="python"
else
    print_error "Python is not installed or not found in PATH"
    echo "Please install Python 3.6 or higher from https://python.org"
    exit 1
fi

# Check Python version
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
print_status "Found Python version: $PYTHON_VERSION"

if ! version_ge "$PYTHON_VERSION" "$PYTHON_MIN_VERSION"; then
    print_error "Python version $PYTHON_MIN_VERSION or higher is required"
    echo "Current version: $PYTHON_VERSION"
    echo "Please upgrade Python from https://python.org"
    exit 1
fi

# Check if pip is available
print_status "Checking pip installation..."
if command_exists pip3; then
    PIP_CMD="pip3"
elif command_exists pip; then
    PIP_CMD="pip"
else
    print_error "pip is not installed"
    echo "Please install pip or use a Python installation that includes pip"
    exit 1
fi

# Create installation directory
print_status "Creating installation directory..."
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Installation directory already exists: $INSTALL_DIR"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/data"

# Copy application files
print_status "Installing TL1 Assistant files..."
cp tl1_web_gui.py "$INSTALL_DIR/"
cp data/commands.json "$INSTALL_DIR/data/"
cp requirements.txt "$INSTALL_DIR/"
cp start-webgui.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/start-webgui.sh"

# Copy documentation
print_status "Installing documentation..."
cp README.md "$INSTALL_DIR/"
cp quick_start.md "$INSTALL_DIR/"
cp tl1_syntax.md "$INSTALL_DIR/"
cp command_examples.json "$INSTALL_DIR/"
cp tap-001.md "$INSTALL_DIR/"
cp directory_structure.md "$INSTALL_DIR/"
cp version.json "$INSTALL_DIR/"

# Install Python dependencies
print_status "Installing Python dependencies..."
cd "$INSTALL_DIR"
$PIP_CMD install -r requirements.txt --user

# Create desktop launcher (Linux)
if command_exists desktop-file-install 2>/dev/null; then
    print_status "Creating desktop launcher..."
    cat > "$INSTALL_DIR/tl1-assistant.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=TL1 Assistant
Comment=Web-based TL1 command interface for telecom network elements
Exec=$INSTALL_DIR/start-webgui.sh
Icon=utilities-terminal
Terminal=false
StartupNotify=true
Categories=Network;Development;
EOF
    
    # Try to install desktop file
    if [ -w "$HOME/.local/share/applications" ]; then
        mkdir -p "$HOME/.local/share/applications"
        cp "$INSTALL_DIR/tl1-assistant.desktop" "$HOME/.local/share/applications/"
        print_status "Desktop launcher created"
    fi
fi

# Create command-line shortcut
print_status "Creating command-line launcher..."
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/tl1-assistant" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
./start-webgui.sh
EOF
chmod +x "$HOME/.local/bin/tl1-assistant"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_warning "Adding $HOME/.local/bin to PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi
fi

# Test installation
print_status "Testing installation..."
cd "$INSTALL_DIR"
$PYTHON_CMD -c "
import sys
sys.path.insert(0, '.')
try:
    from tl1_web_gui import TL1Backend, load_commands_data
    data = load_commands_data()
    print(f'✅ Installation test passed - {len(data.get(\"commands\", {}))} commands loaded')
except Exception as e:
    print(f'❌ Installation test failed: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}   Installation Completed Successfully${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "Installation location: ${BLUE}$INSTALL_DIR${NC}"
    echo ""
    echo "To start TL1 Assistant:"
    echo -e "  Command line: ${YELLOW}tl1-assistant${NC}"
    echo -e "  Manual start: ${YELLOW}cd '$INSTALL_DIR' && ./start-webgui.sh${NC}"
    echo ""
    echo "The web interface will open at: http://localhost:8080"
    echo ""
    echo -e "Documentation available in: ${BLUE}$INSTALL_DIR${NC}"
    echo "  • README.md - Project overview"
    echo "  • quick_start.md - Getting started guide"
    echo "  • tap-001.md - Troubleshooting procedures"
    echo ""
    echo -e "${GREEN}Installation complete! ${NC}🚀"
    echo ""
    
    # Offer to start immediately
    read -p "Would you like to start TL1 Assistant now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Starting TL1 Assistant..."
        exec "$INSTALL_DIR/start-webgui.sh"
    fi
else
    print_error "Installation test failed"
    echo "Please check the error messages above and try again"
    exit 1
fi
#!/bin/bash
# TL1 Assistant Release Build Script
# Creates downloadable distribution packages

set -e

# Build configuration
VERSION=$(grep '"version"' version.json | cut -d'"' -f4)
BUILD_DATE=$(date +"%Y-%m-%d")
RELEASE_NAME="TL1Assistant-v${VERSION}"
DIST_DIR="dist"
RELEASES_DIR="releases"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}   TL1 Assistant Release Builder      ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "Version: ${GREEN}${VERSION}${NC}"
echo -e "Build Date: ${GREEN}${BUILD_DATE}${NC}"
echo -e "Release Name: ${GREEN}${RELEASE_NAME}${NC}"
echo ""

# Clean and create directories
echo -e "${YELLOW}[BUILD]${NC} Cleaning build directories..."
rm -rf "$DIST_DIR"
rm -rf "$RELEASES_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$RELEASES_DIR"

# Create release directory structure
RELEASE_DIR="$DIST_DIR/$RELEASE_NAME"
mkdir -p "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR/data"
mkdir -p "$RELEASE_DIR/scripts"
mkdir -p "$RELEASE_DIR/docs"

echo -e "${YELLOW}[BUILD]${NC} Copying core application files..."

# Copy core files
cp tl1_web_gui.py "$RELEASE_DIR/"
cp data/commands.json "$RELEASE_DIR/data/"
cp requirements.txt "$RELEASE_DIR/"
cp version.json "$RELEASE_DIR/"

# Copy launchers
cp start-webgui.sh "$RELEASE_DIR/"
cp Start-WebGUI.cmd "$RELEASE_DIR/"
chmod +x "$RELEASE_DIR/start-webgui.sh"

# Copy installation scripts
cp scripts/install.sh "$RELEASE_DIR/scripts/"
cp scripts/install.bat "$RELEASE_DIR/scripts/"
chmod +x "$RELEASE_DIR/scripts/install.sh"

# Copy documentation to docs subfolder
cp README.md "$RELEASE_DIR/docs/"
cp quick_start.md "$RELEASE_DIR/docs/"
cp tl1_syntax.md "$RELEASE_DIR/docs/"
cp command_examples.json "$RELEASE_DIR/docs/"
cp tap-001.md "$RELEASE_DIR/docs/"
cp directory_structure.md "$RELEASE_DIR/docs/"

# Create main README for release
cat > "$RELEASE_DIR/README.txt" << EOF
TL1 Assistant v${VERSION}
=========================

QUICK START:
-----------
1. Run the installer for your platform:
   - Linux/macOS: ./scripts/install.sh
   - Windows: scripts\install.bat

2. Or manually start:
   - Linux/macOS: ./start-webgui.sh
   - Windows: Start-WebGUI.cmd

3. Open your browser to: http://localhost:8080

WHAT'S INCLUDED:
---------------
• tl1_web_gui.py - Main application (766 lines)
• data/commands.json - 630+ TL1 commands database
• scripts/ - Installation scripts for all platforms
• docs/ - Comprehensive documentation

SYSTEM REQUIREMENTS:
-------------------
• Python 3.6 or higher
• Flask library (pip install flask)
• Modern web browser
• Network access to TL1 devices

DOCUMENTATION:
-------------
• docs/README.md - Complete project overview
• docs/quick_start.md - Getting started guide
• docs/tap-001.md - Troubleshooting procedures
• docs/tl1_syntax.md - TL1 command reference

For detailed installation and usage instructions, see docs/quick_start.md

Visit the project repository for updates and support.

Build Date: ${BUILD_DATE}
Version: ${VERSION}
EOF

echo -e "${YELLOW}[BUILD]${NC} Creating distribution packages..."

# Create ZIP archive
cd "$DIST_DIR"
zip -r "${RELEASE_NAME}.zip" "$RELEASE_NAME/" > /dev/null
echo -e "${GREEN}[CREATED]${NC} ${RELEASE_NAME}.zip"

# Create TAR.GZ archive
tar -czf "${RELEASE_NAME}.tar.gz" "$RELEASE_NAME/"
echo -e "${GREEN}[CREATED]${NC} ${RELEASE_NAME}.tar.gz"

# Move to releases directory
mv "${RELEASE_NAME}.zip" "../$RELEASES_DIR/"
mv "${RELEASE_NAME}.tar.gz" "../$RELEASES_DIR/"

cd ..

# Create checksums
echo -e "${YELLOW}[BUILD]${NC} Generating checksums..."
cd "$RELEASES_DIR"
sha256sum *.zip *.tar.gz > "${RELEASE_NAME}-checksums.txt"
cd ..

# Create release info
cat > "$RELEASES_DIR/${RELEASE_NAME}-info.json" << EOF
{
  "release": {
    "version": "${VERSION}",
    "build_date": "${BUILD_DATE}",
    "name": "${RELEASE_NAME}",
    "files": [
      {
        "name": "${RELEASE_NAME}.zip",
        "type": "zip",
        "platform": "cross-platform",
        "size": "$(stat -f%z "$RELEASES_DIR/${RELEASE_NAME}.zip" 2>/dev/null || stat -c%s "$RELEASES_DIR/${RELEASE_NAME}.zip")"
      },
      {
        "name": "${RELEASE_NAME}.tar.gz",
        "type": "tar.gz",
        "platform": "linux-macos",
        "size": "$(stat -f%z "$RELEASES_DIR/${RELEASE_NAME}.tar.gz" 2>/dev/null || stat -c%s "$RELEASES_DIR/${RELEASE_NAME}.tar.gz")"
      }
    ],
    "checksums": "${RELEASE_NAME}-checksums.txt"
  }
}
EOF

# Calculate total file sizes
ZIP_SIZE=$(stat -f%z "$RELEASES_DIR/${RELEASE_NAME}.zip" 2>/dev/null || stat -c%s "$RELEASES_DIR/${RELEASE_NAME}.zip")
TAR_SIZE=$(stat -f%z "$RELEASES_DIR/${RELEASE_NAME}.tar.gz" 2>/dev/null || stat -c%s "$RELEASES_DIR/${RELEASE_NAME}.tar.gz")

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}   Build Completed Successfully!     ${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Release files created in: ${RELEASES_DIR}/"
echo ""
echo "Distribution packages:"
echo -e "  📦 ${RELEASE_NAME}.zip ($(numfmt --to=iec $ZIP_SIZE))"
echo -e "  📦 ${RELEASE_NAME}.tar.gz ($(numfmt --to=iec $TAR_SIZE))"
echo -e "  🔒 ${RELEASE_NAME}-checksums.txt"
echo -e "  📋 ${RELEASE_NAME}-info.json"
echo ""
echo "Installation instructions:"
echo "  1. Extract downloaded package"
echo "  2. Run installer script for your platform"
echo "  3. Follow installation prompts"
echo ""
echo -e "${GREEN}Ready for distribution! 🚀${NC}"
echo ""

# Offer to test the package
read -p "Would you like to test the ZIP package? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[TEST]${NC} Testing ZIP package..."
    TEST_DIR="test-install-$$"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    unzip -q "../$RELEASES_DIR/${RELEASE_NAME}.zip"
    cd "$RELEASE_NAME"
    
    echo "Testing core imports..."
    python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from tl1_web_gui import TL1Backend, load_commands_data, load_version_info
    data = load_commands_data()
    version = load_version_info()
    print(f'✅ Package test passed')
    print(f'   Commands: {len(data.get(\"commands\", {}))}')
    print(f'   Version: {version.get(\"version\", \"unknown\")}')
except Exception as e:
    print(f'❌ Package test failed: {e}')
    exit(1)
"
    
    cd ../..
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}[TEST]${NC} Package test completed successfully!"
fi
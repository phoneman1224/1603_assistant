#!/bin/bash
# Simple cleanup script for removing backup and temporary files

echo "Starting repository cleanup..."

# Find and remove backup files
find . -name "*.bak" -type f -delete
find . -name "*.bak-*" -type f -delete
find . -name "*.pre_*" -type f -delete

# Find and remove temporary directories
find . -name "*backup*" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove Python cache files
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -type f -delete

# Remove Node.js cache files
find . -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove empty directories
find . -type d -empty -delete 2>/dev/null || true

echo "Cleanup complete!"
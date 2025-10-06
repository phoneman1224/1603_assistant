#!/bin/bash
# Setup script for local scheduled cleanup
# This script sets up a cron job to run the cleanup script weekly

# Ensure we're in the repository root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

# Ensure cleanup script is executable
chmod +x scripts/cleanup.sh

# Create a wrapper script that will run in the correct directory
WRAPPER_SCRIPT="$REPO_ROOT/scripts/run_scheduled_cleanup.sh"
cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to repository root
cd "$REPO_ROOT" || exit 1

# Set up log file
LOG_FILE="$REPO_ROOT/logs/cleanup_$(date +\%Y\%m\%d_\%H\%M\%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Run git operations
log "Starting scheduled cleanup"
git pull origin main >> "$LOG_FILE" 2>&1

# Run cleanup script with automatic confirmation
log "Running cleanup script"
echo "y" | ./scripts/cleanup.sh >> "$LOG_FILE" 2>&1

# Check if there are changes
if [[ -n "$(git status --porcelain)" ]]; then
    log "Changes detected, creating commit"
    
    # Create cleanup branch
    cleanup_branch="cleanup/$(date +%Y%m%d_%H%M%S)"
    git checkout -b "$cleanup_branch" >> "$LOG_FILE" 2>&1
    
    # Commit changes
    git add . >> "$LOG_FILE" 2>&1
    git commit -m "chore: Automated cleanup $(date +%Y-%m-%d)

    Removed:
    $(git status --porcelain | sed 's/^D /- Deleted: /')" >> "$LOG_FILE" 2>&1
    
    # Push changes
    log "Pushing changes"
    git push origin "$cleanup_branch" >> "$LOG_FILE" 2>&1
    
    # Create pull request if gh CLI is available
    if command -v gh &> /dev/null; then
        log "Creating pull request"
        gh pr create \
            --title "🧹 Automated Cleanup $(date +%Y-%m-%d)" \
            --body "This PR was created by the automated cleanup script.

### Changes
$(git status --porcelain | sed 's/^D /- Deleted: /')

### Storage Saved
$(du -sh cleanup_backups 2>/dev/null || echo 'No backups created')

### Validation
- [ ] Check that no important files were removed
- [ ] Verify backups are available if needed
- [ ] Test that everything still works as expected" \
            --label "maintenance" \
            --label "automated" >> "$LOG_FILE" 2>&1
    else
        log "gh CLI not available, skipping PR creation"
    fi
else
    log "No changes detected"
fi

# Rotate logs (keep last 10)
find "$REPO_ROOT/logs" -name "cleanup_*.log" -type f -mtime +30 -delete

log "Cleanup complete"
EOF

# Make wrapper script executable
chmod +x "$WRAPPER_SCRIPT"

# Create the cron job
CRON_CMD="0 2 * * 0 $WRAPPER_SCRIPT"

# Add to crontab if it doesn't exist
(crontab -l 2>/dev/null | grep -Fq "$WRAPPER_SCRIPT") || {
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
}

echo "Scheduled cleanup has been set up:"
echo "- Wrapper script created at: $WRAPPER_SCRIPT"
echo "- Will run every Sunday at 2 AM"
echo "- Logs will be saved to: $REPO_ROOT/logs/cleanup_*.log"
echo "- Log rotation: 30 days"
echo ""
echo "You can test the cleanup by running:"
echo "$WRAPPER_SCRIPT"
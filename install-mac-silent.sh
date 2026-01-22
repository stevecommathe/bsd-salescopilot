#!/bin/bash
#
# BSD Sales Copilot - Silent Mac Installer
# Non-interactive version for Automator/app distribution
#

set -e

# --- Configuration (baked in for team distribution) ---
# These are shared team credentials - safe to distribute internally
GEMINI_API_KEY="__GEMINI_API_KEY__"
SUPABASE_URL="__SUPABASE_URL__"
SUPABASE_ANON_KEY="__SUPABASE_ANON_KEY__"
GITHUB_REPO="Black-Sand-Distribution/bsd-salescopilot"
GITHUB_BRANCH="main"

# Auto-detect user ID from system
USER_ID=$(whoami)

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COPILOT_PATH="$SCRIPT_DIR"

# Log file for debugging
LOG_FILE="$HOME/Library/Logs/BSDSalesCopilot/install.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "=== BSD Sales Copilot Installation Started ==="
log "Install path: $COPILOT_PATH"
log "User ID: $USER_ID"

# --- Check for Espanso ---
if ! command -v espanso &> /dev/null; then
    log "ERROR: Espanso not found"
    echo "ESPANSO_NOT_FOUND"
    exit 1
fi
log "Espanso found"

# --- Check for Python 3 ---
if ! command -v python3 &> /dev/null; then
    log "ERROR: Python 3 not found"
    echo "PYTHON_NOT_FOUND"
    exit 1
fi
log "Python 3 found"

# --- Get Espanso config directory ---
ESPANSO_CONFIG_DIR="$HOME/.config/espanso"
if [ ! -d "$ESPANSO_CONFIG_DIR" ]; then
    ESPANSO_CONFIG_DIR="$HOME/Library/Application Support/espanso"
fi

if [ ! -d "$ESPANSO_CONFIG_DIR" ]; then
    log "ERROR: Espanso config not found"
    echo "ESPANSO_CONFIG_NOT_FOUND"
    exit 1
fi
log "Espanso config: $ESPANSO_CONFIG_DIR"

# Create match directory if needed
mkdir -p "$ESPANSO_CONFIG_DIR/match"

# --- Create symlinks ---
log "Creating symlinks..."
for file in "$COPILOT_PATH/match"/*.yml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        target="$ESPANSO_CONFIG_DIR/match/$filename"

        # Remove existing
        if [ -L "$target" ] || [ -f "$target" ]; then
            rm -f "$target"
        fi

        ln -sf "$file" "$target"
        log "Linked: $filename"
    fi
done

# --- Set environment variable ---
log "Setting environment variable..."
export BSD_COPILOT_PATH="$COPILOT_PATH"
launchctl setenv BSD_COPILOT_PATH "$COPILOT_PATH"

# Update shell profile
for profile in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    if [ -f "$profile" ]; then
        # Remove old entries
        sed -i '' '/# BSD Sales Copilot/d' "$profile" 2>/dev/null || true
        sed -i '' '/BSD_COPILOT_PATH/d' "$profile" 2>/dev/null || true
    fi
done

# Add to .zshrc (default on modern macOS)
echo "" >> "$HOME/.zshrc"
echo "# BSD Sales Copilot" >> "$HOME/.zshrc"
echo "export BSD_COPILOT_PATH=\"$COPILOT_PATH\"" >> "$HOME/.zshrc"
log "Updated .zshrc"

# --- Create config.json ---
CONFIG_FILE="$COPILOT_PATH/scripts/config.json"
log "Creating config.json..."
cat > "$CONFIG_FILE" << EOF
{
  "provider": "gemini",
  "gemini_api_key": "$GEMINI_API_KEY",
  "supabase_url": "$SUPABASE_URL",
  "supabase_anon_key": "$SUPABASE_ANON_KEY",
  "log_usage": true,
  "log_responses": false,
  "user_id": "$USER_ID",
  "github_repo": "$GITHUB_REPO",
  "github_branch": "$GITHUB_BRANCH",
  "sync_enabled": true
}
EOF
log "Config saved"

# --- Install LaunchAgents ---
log "Installing background services..."
mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$COPILOT_PATH/scripts/.logs"
mkdir -p "$HOME/Library/Logs/BSDSalesCopilot"

# Environment variable persistence
ENV_PLIST="$HOME/Library/LaunchAgents/com.bsd.salescopilot.env.plist"
if [ -f "$COPILOT_PATH/install/com.bsd.salescopilot.env.plist" ]; then
    sed "s|__BSD_COPILOT_PATH__|$COPILOT_PATH|g" "$COPILOT_PATH/install/com.bsd.salescopilot.env.plist" > "$ENV_PLIST"
    launchctl unload "$ENV_PLIST" 2>/dev/null || true
    launchctl load "$ENV_PLIST"
    log "Installed env service"
fi

# Log sync service
SYNC_PLIST="$HOME/Library/LaunchAgents/com.bsd.salescopilot.sync.plist"
if [ -f "$COPILOT_PATH/install/com.bsd.salescopilot.sync.plist" ]; then
    sed "s|__BSD_COPILOT_PATH__|$COPILOT_PATH|g" "$COPILOT_PATH/install/com.bsd.salescopilot.sync.plist" > "$SYNC_PLIST"
    launchctl unload "$SYNC_PLIST" 2>/dev/null || true
    launchctl load "$SYNC_PLIST"
    log "Installed log sync service"
fi

# Snippet sync service
SNIPPET_PLIST="$HOME/Library/LaunchAgents/com.bsd.salescopilot.snippetsync.plist"
if [ -f "$COPILOT_PATH/install/com.bsd.salescopilot.snippetsync.plist" ]; then
    sed -e "s|__BSD_COPILOT_PATH__|$COPILOT_PATH|g" -e "s|__HOME__|$HOME|g" "$COPILOT_PATH/install/com.bsd.salescopilot.snippetsync.plist" > "$SNIPPET_PLIST"
    launchctl unload "$SNIPPET_PLIST" 2>/dev/null || true
    launchctl load "$SNIPPET_PLIST"
    log "Installed snippet sync service"
fi

# --- Restart Espanso ---
log "Restarting Espanso..."
espanso restart 2>/dev/null || true
log "Espanso restarted"

log "=== Installation Complete ==="
echo "SUCCESS"

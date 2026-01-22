#!/bin/bash
#
# BSD Sales Copilot - Mac Installer
# Sets up Espanso snippets and configuration
#

set -e  # Exit on error

echo "==================================="
echo "BSD Sales Copilot - Mac Installer"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# --- Step 1: Check for Espanso ---
echo "Checking for Espanso..."
if ! command -v espanso &> /dev/null; then
    echo -e "${RED}Error: Espanso is not installed.${NC}"
    echo "Please install Espanso first: https://espanso.org/install/"
    exit 1
fi
echo -e "${GREEN}✓ Espanso found${NC}"

# --- Step 2: Check for Python 3 ---
echo "Checking for Python 3..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed.${NC}"
    echo "Please install Python 3 first."
    exit 1
fi
echo -e "${GREEN}✓ Python 3 found${NC}"

# --- Step 3: Determine installation source ---
echo ""
echo "Installation source: $SCRIPT_DIR"

# Check if this is running from Google Drive
if [[ "$SCRIPT_DIR" == *"Google Drive"* ]] || [[ "$SCRIPT_DIR" == *"GoogleDrive"* ]]; then
    echo -e "${GREEN}✓ Running from Google Drive (team sync enabled)${NC}"
    COPILOT_PATH="$SCRIPT_DIR"
else
    echo -e "${YELLOW}Note: Not running from Google Drive.${NC}"
    echo "For team sync, copy this folder to Google Drive and run installer from there."
    echo ""
    read -p "Continue with local installation? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    COPILOT_PATH="$SCRIPT_DIR"
fi

# --- Step 4: Get Espanso config directory ---
ESPANSO_CONFIG_DIR="$HOME/.config/espanso"
if [ ! -d "$ESPANSO_CONFIG_DIR" ]; then
    # Try alternative location (older Espanso versions)
    ESPANSO_CONFIG_DIR="$HOME/Library/Application Support/espanso"
fi

if [ ! -d "$ESPANSO_CONFIG_DIR" ]; then
    echo -e "${RED}Error: Espanso config directory not found.${NC}"
    echo "Expected: ~/.config/espanso or ~/Library/Application Support/espanso"
    exit 1
fi
echo -e "${GREEN}✓ Espanso config: $ESPANSO_CONFIG_DIR${NC}"

# Create match directory if it doesn't exist
mkdir -p "$ESPANSO_CONFIG_DIR/match"

# --- Step 5: Create symlinks ---
echo ""
echo "Creating symlinks to Espanso config..."

# Remove existing symlinks if they exist
for file in "$COPILOT_PATH/match"/*.yml; do
    filename=$(basename "$file")
    target="$ESPANSO_CONFIG_DIR/match/$filename"

    if [ -L "$target" ]; then
        rm "$target"
        echo "  Removed existing symlink: $filename"
    elif [ -f "$target" ]; then
        echo -e "${YELLOW}  Warning: $filename exists and is not a symlink. Backing up...${NC}"
        mv "$target" "$target.backup"
    fi

    ln -sf "$file" "$target"
    echo -e "${GREEN}  ✓ Linked: $filename${NC}"
done

# --- Step 6: Set environment variable ---
echo ""
echo "Setting BSD_COPILOT_PATH environment variable..."

# Determine shell profile
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_PROFILE="$HOME/.bash_profile"
else
    SHELL_PROFILE="$HOME/.bashrc"
fi

# Check if already set
if grep -q "BSD_COPILOT_PATH" "$SHELL_PROFILE" 2>/dev/null; then
    echo "  BSD_COPILOT_PATH already in $SHELL_PROFILE"
    # Update the value
    sed -i '' "s|export BSD_COPILOT_PATH=.*|export BSD_COPILOT_PATH=\"$COPILOT_PATH\"|" "$SHELL_PROFILE"
    echo -e "${GREEN}  ✓ Updated BSD_COPILOT_PATH${NC}"
else
    echo "" >> "$SHELL_PROFILE"
    echo "# BSD Sales Copilot" >> "$SHELL_PROFILE"
    echo "export BSD_COPILOT_PATH=\"$COPILOT_PATH\"" >> "$SHELL_PROFILE"
    echo -e "${GREEN}  ✓ Added BSD_COPILOT_PATH to $SHELL_PROFILE${NC}"
fi

# Export for current session
export BSD_COPILOT_PATH="$COPILOT_PATH"

# Set for GUI apps (Espanso needs this)
launchctl setenv BSD_COPILOT_PATH "$COPILOT_PATH"

# Make it persist across reboots
ENV_PLIST_TEMPLATE="$COPILOT_PATH/install/com.bsd.salescopilot.env.plist"
ENV_PLIST_TARGET="$HOME/Library/LaunchAgents/com.bsd.salescopilot.env.plist"
if [ -f "$ENV_PLIST_TEMPLATE" ]; then
    sed "s|__BSD_COPILOT_PATH__|$COPILOT_PATH|g" "$ENV_PLIST_TEMPLATE" > "$ENV_PLIST_TARGET"
    launchctl unload "$ENV_PLIST_TARGET" 2>/dev/null || true
    launchctl load "$ENV_PLIST_TARGET"
    echo -e "${GREEN}  ✓ Environment variable will persist across reboots${NC}"
fi

# --- Step 7: Configure API keys ---
echo ""
CONFIG_FILE="$COPILOT_PATH/scripts/config.json"

if [ -f "$CONFIG_FILE" ]; then
    echo "Config file already exists at: $CONFIG_FILE"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing config."
    else
        rm "$CONFIG_FILE"
    fi
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Setting up configuration..."
    echo ""

    # Get API key
    read -p "Enter your Gemini API key (or press Enter to skip): " GEMINI_KEY

    # Get user ID (machine name)
    DEFAULT_USER=$(whoami)
    read -p "Enter your user ID [$DEFAULT_USER]: " USER_ID
    USER_ID=${USER_ID:-$DEFAULT_USER}

    # Get Supabase details (optional)
    echo ""
    echo "Supabase logging (optional - press Enter to skip):"
    read -p "  Supabase URL: " SUPABASE_URL
    read -p "  Supabase anon key: " SUPABASE_KEY

    # GitHub repo settings (change this when migrating to BSD repo)
    GITHUB_REPO="stevecommathe/bsd-salescopilot"
    GITHUB_BRANCH="main"

    # Create config file
    cat > "$CONFIG_FILE" << EOF
{
  "provider": "gemini",
  "gemini_api_key": "$GEMINI_KEY",
  "supabase_url": "$SUPABASE_URL",
  "supabase_anon_key": "$SUPABASE_KEY",
  "log_usage": true,
  "log_responses": false,
  "user_id": "$USER_ID",
  "github_repo": "$GITHUB_REPO",
  "github_branch": "$GITHUB_BRANCH",
  "sync_enabled": true
}
EOF
    echo -e "${GREEN}✓ Config saved to $CONFIG_FILE${NC}"
fi

# --- Step 8: Set up background services ---
echo ""
echo "Setting up background services..."

# Create logs directories
mkdir -p "$COPILOT_PATH/scripts/.logs"
mkdir -p "$HOME/Library/Logs/BSDSalesCopilot"

# --- 8a: Log sync (local logs to Supabase) ---
PLIST_TEMPLATE="$COPILOT_PATH/install/com.bsd.salescopilot.sync.plist"
PLIST_TARGET="$HOME/Library/LaunchAgents/com.bsd.salescopilot.sync.plist"

if [ -f "$PLIST_TEMPLATE" ]; then
    sed "s|__BSD_COPILOT_PATH__|$COPILOT_PATH|g" "$PLIST_TEMPLATE" > "$PLIST_TARGET"
    launchctl unload "$PLIST_TARGET" 2>/dev/null || true
    launchctl load "$PLIST_TARGET"
    echo -e "${GREEN}  ✓ Log sync service installed${NC}"
fi

# --- 8b: Snippet sync (GitHub to local) ---
SNIPPET_PLIST_TEMPLATE="$COPILOT_PATH/install/com.bsd.salescopilot.snippetsync.plist"
SNIPPET_PLIST_TARGET="$HOME/Library/LaunchAgents/com.bsd.salescopilot.snippetsync.plist"

if [ -f "$SNIPPET_PLIST_TEMPLATE" ]; then
    sed -e "s|__BSD_COPILOT_PATH__|$COPILOT_PATH|g" -e "s|__HOME__|$HOME|g" "$SNIPPET_PLIST_TEMPLATE" > "$SNIPPET_PLIST_TARGET"
    launchctl unload "$SNIPPET_PLIST_TARGET" 2>/dev/null || true
    launchctl load "$SNIPPET_PLIST_TARGET"
    echo -e "${GREEN}  ✓ Snippet sync service installed (updates from GitHub every 5 min)${NC}"
fi

echo -e "${GREEN}  ✓ Logs will be written to ~/Library/Logs/BSDSalesCopilot/${NC}"

# --- Step 9: Restart Espanso ---
echo ""
echo "Restarting Espanso..."
espanso restart
echo -e "${GREEN}✓ Espanso restarted${NC}"

# --- Done ---
echo ""
echo "==================================="
echo -e "${GREEN}Installation complete!${NC}"
echo "==================================="
echo ""
echo "Available triggers:"
echo "  ;hi      - Friendly greeting"
echo "  ;hello   - Hello with help offer"
echo "  ;thanks  - Thank you closing"
echo "  ;sig     - Email signature"
echo "  ;p1      - AI polish (1 option)"
echo "  ;p2      - AI polish (2 options)"
echo "  ;p3      - AI polish (3 options)"
echo "  ;reply   - AI reply from knowledge base"
echo ""
echo "To test, copy some text and type ;p1 in any app."
echo ""
echo "Background services:"
echo "  • Snippets auto-update from GitHub every 5 minutes"
echo "  • Usage logs sync to Supabase (if configured)"
echo "  • Logs: ~/Library/Logs/BSDSalesCopilot/"
echo ""
echo -e "${YELLOW}Note: Snippets will update automatically. No action needed!${NC}"

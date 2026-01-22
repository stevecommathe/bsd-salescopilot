#!/bin/bash
#
# BSD Sales Copilot - Mac Uninstaller
# Removes all installed components
#

echo "==================================="
echo "BSD Sales Copilot - Uninstaller"
echo "==================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Step 1: Unload LaunchAgents ---
echo "Stopping background services..."
launchctl unload ~/Library/LaunchAgents/com.bsd.salescopilot.env.plist 2>/dev/null && echo -e "${GREEN}  ✓ Stopped env service${NC}"
launchctl unload ~/Library/LaunchAgents/com.bsd.salescopilot.sync.plist 2>/dev/null && echo -e "${GREEN}  ✓ Stopped sync service${NC}"
launchctl unload ~/Library/LaunchAgents/com.bsd.salescopilot.snippetsync.plist 2>/dev/null && echo -e "${GREEN}  ✓ Stopped snippet sync service${NC}"

# --- Step 2: Remove LaunchAgent plists ---
echo ""
echo "Removing LaunchAgent files..."
rm -f ~/Library/LaunchAgents/com.bsd.salescopilot.env.plist && echo -e "${GREEN}  ✓ Removed env.plist${NC}"
rm -f ~/Library/LaunchAgents/com.bsd.salescopilot.sync.plist && echo -e "${GREEN}  ✓ Removed sync.plist${NC}"
rm -f ~/Library/LaunchAgents/com.bsd.salescopilot.snippetsync.plist && echo -e "${GREEN}  ✓ Removed snippetsync.plist${NC}"

# --- Step 3: Remove symlinks from Espanso ---
echo ""
echo "Removing Espanso symlinks..."
ESPANSO_MATCH="$HOME/.config/espanso/match"
if [ ! -d "$ESPANSO_MATCH" ]; then
    ESPANSO_MATCH="$HOME/Library/Application Support/espanso/match"
fi

for file in "$ESPANSO_MATCH"/*.yml; do
    if [ -L "$file" ]; then
        # Check if symlink points to bsd-salescopilot
        target=$(readlink "$file")
        if [[ "$target" == *"bsd-salescopilot"* ]]; then
            rm "$file"
            echo -e "${GREEN}  ✓ Removed symlink: $(basename "$file")${NC}"
        fi
    fi
done

# --- Step 4: Unset environment variable ---
echo ""
echo "Unsetting environment variable..."
launchctl unsetenv BSD_COPILOT_PATH 2>/dev/null && echo -e "${GREEN}  ✓ Unset BSD_COPILOT_PATH${NC}"

# --- Step 5: Remove from shell profile ---
echo ""
echo "Cleaning shell profile..."
for profile in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    if [ -f "$profile" ]; then
        if grep -q "BSD_COPILOT_PATH" "$profile"; then
            # Remove the BSD Sales Copilot lines
            sed -i '' '/# BSD Sales Copilot/d' "$profile"
            sed -i '' '/BSD_COPILOT_PATH/d' "$profile"
            echo -e "${GREEN}  ✓ Cleaned $profile${NC}"
        fi
    fi
done

# --- Step 6: Optional - Remove logs ---
echo ""
read -p "Remove log files? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/Library/Logs/BSDSalesCopilot
    echo -e "${GREEN}  ✓ Removed log directory${NC}"
fi

# --- Step 7: Optional - Remove config ---
echo ""
read -p "Remove config.json (contains API keys)? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    rm -f "$SCRIPT_DIR/scripts/config.json"
    echo -e "${GREEN}  ✓ Removed config.json${NC}"
fi

# --- Step 8: Restart Espanso ---
echo ""
echo "Restarting Espanso..."
espanso restart 2>/dev/null && echo -e "${GREEN}  ✓ Espanso restarted${NC}"

echo ""
echo "==================================="
echo -e "${GREEN}Uninstall complete!${NC}"
echo "==================================="
echo ""
echo "Note: Espanso itself is still installed."
echo "To remove Espanso: brew uninstall espanso"
echo ""
echo "To reinstall BSD Sales Copilot, run:"
echo "  ./install-mac.sh"
echo ""

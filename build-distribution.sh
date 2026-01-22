#!/bin/bash
#
# BSD Sales Copilot - Build Distribution Package
# Creates a folder ready to distribute to the team
#

set -e

echo "==================================="
echo "Building BSD Sales Copilot Distribution"
echo "==================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SCRIPT_DIR/dist"
PACKAGE_NAME="BSD-Sales-Copilot"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$PACKAGE_NAME"

echo "Copying files..."

# Copy essential directories
cp -r "$SCRIPT_DIR/match" "$BUILD_DIR/$PACKAGE_NAME/"
cp -r "$SCRIPT_DIR/scripts" "$BUILD_DIR/$PACKAGE_NAME/"
cp -r "$SCRIPT_DIR/knowledge" "$BUILD_DIR/$PACKAGE_NAME/"
cp -r "$SCRIPT_DIR/install" "$BUILD_DIR/$PACKAGE_NAME/"

# Remove dev files from scripts
rm -f "$BUILD_DIR/$PACKAGE_NAME/scripts/config.json" 2>/dev/null || true
rm -rf "$BUILD_DIR/$PACKAGE_NAME/scripts/.logs" 2>/dev/null || true
rm -rf "$BUILD_DIR/$PACKAGE_NAME/scripts/__pycache__" 2>/dev/null || true

# Copy installer scripts
cp "$SCRIPT_DIR/install-mac-silent.sh" "$BUILD_DIR/$PACKAGE_NAME/"
cp "$SCRIPT_DIR/uninstall-mac.sh" "$BUILD_DIR/$PACKAGE_NAME/"

# Copy and compile apps
echo "Building installer apps..."
cd "$BUILD_DIR/$PACKAGE_NAME"
osacompile -o "Install BSD Sales Copilot.app" "$SCRIPT_DIR/installers/InstallBSDSalesCopilot.applescript"
osacompile -o "Uninstall BSD Sales Copilot.app" "$SCRIPT_DIR/installers/UninstallBSDSalesCopilot.applescript"

# Make scripts executable
chmod +x install-mac-silent.sh
chmod +x uninstall-mac.sh

# Create README for distribution
cat > "README.txt" << 'EOF'
BSD Sales Copilot - Installation Guide
======================================

BEFORE YOU START:
1. Install Espanso from: https://espanso.org/install/
   (Download the Mac version and drag to Applications)

2. Open Espanso once and grant accessibility permissions when prompted

INSTALLATION:
1. Double-click "Install BSD Sales Copilot.app"
2. Click "Install" when prompted
3. Done!

USAGE:
Type these shortcuts in any app:
- ;hi     → Friendly greeting
- ;hello  → Hello with help offer
- ;thanks → Thank you closing
- ;reply  → AI-powered response (copy a question first)
- ;p1     → AI polish your text (copy text first)

UNINSTALL:
Double-click "Uninstall BSD Sales Copilot.app"

SUPPORT:
Contact: [Your contact info here]

Shortcuts automatically update - no action needed!
EOF

# Create zip
echo "Creating zip archive..."
cd "$BUILD_DIR"
zip -r "$PACKAGE_NAME.zip" "$PACKAGE_NAME" -x "*.DS_Store"

echo ""
echo "==================================="
echo "Build complete!"
echo "==================================="
echo ""
echo "Distribution package: $BUILD_DIR/$PACKAGE_NAME.zip"
echo "Distribution folder:  $BUILD_DIR/$PACKAGE_NAME/"
echo ""
echo "BEFORE DISTRIBUTING:"
echo "1. Edit install-mac-silent.sh and add real API keys:"
echo "   - GEMINI_API_KEY"
echo "   - SUPABASE_URL (optional)"
echo "   - SUPABASE_ANON_KEY (optional)"
echo ""
echo "2. Rebuild after adding keys:"
echo "   ./build-distribution.sh"
echo ""

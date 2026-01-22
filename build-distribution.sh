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
CREDENTIALS_FILE="$SCRIPT_DIR/credentials.env"

# Check for credentials file
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo ""
    echo "ERROR: credentials.env not found!"
    echo ""
    echo "Create credentials.env with:"
    echo '  GEMINI_API_KEY="your-key-here"'
    echo '  SUPABASE_URL="https://xxx.supabase.co"'
    echo '  SUPABASE_ANON_KEY="your-anon-key"'
    echo ""
    exit 1
fi

# Load credentials
source "$CREDENTIALS_FILE"

if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" == "" ]; then
    echo "ERROR: GEMINI_API_KEY not set in credentials.env"
    exit 1
fi

echo "✓ Credentials loaded"

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

# Copy and process installer script (replace placeholders with real credentials)
echo "Baking in credentials..."
sed -e "s|__GEMINI_API_KEY__|$GEMINI_API_KEY|g" \
    -e "s|__SUPABASE_URL__|${SUPABASE_URL:-}|g" \
    -e "s|__SUPABASE_ANON_KEY__|${SUPABASE_ANON_KEY:-}|g" \
    "$SCRIPT_DIR/install-mac-silent.sh" > "$BUILD_DIR/$PACKAGE_NAME/install-mac-silent.sh"

cp "$SCRIPT_DIR/uninstall-mac.sh" "$BUILD_DIR/$PACKAGE_NAME/"

# Make scripts executable
chmod +x "$BUILD_DIR/$PACKAGE_NAME/install-mac-silent.sh"
chmod +x "$BUILD_DIR/$PACKAGE_NAME/uninstall-mac.sh"

# Build installer apps
echo "Building installer apps..."
cd "$BUILD_DIR/$PACKAGE_NAME"
osacompile -o "Install BSD Sales Copilot.app" "$SCRIPT_DIR/installers/InstallBSDSalesCopilot.applescript"
osacompile -o "Uninstall BSD Sales Copilot.app" "$SCRIPT_DIR/installers/UninstallBSDSalesCopilot.applescript"

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
Contact: steven@blacksanddistribution.com

Shortcuts automatically update - no action needed!
EOF

# Create zip
echo "Creating zip archive..."
cd "$BUILD_DIR"
zip -r "$PACKAGE_NAME.zip" "$PACKAGE_NAME" -x "*.DS_Store"

echo ""
echo "==================================="
echo "✓ Build complete!"
echo "==================================="
echo ""
echo "Distribution package: $BUILD_DIR/$PACKAGE_NAME.zip"
echo "Distribution folder:  $BUILD_DIR/$PACKAGE_NAME/"
echo ""
echo "Credentials baked in:"
echo "  - Gemini API key: ✓"
[ -n "$SUPABASE_URL" ] && echo "  - Supabase URL: ✓" || echo "  - Supabase URL: (not set)"
[ -n "$SUPABASE_ANON_KEY" ] && echo "  - Supabase key: ✓" || echo "  - Supabase key: (not set)"
echo ""
echo "Ready to distribute!"
echo ""

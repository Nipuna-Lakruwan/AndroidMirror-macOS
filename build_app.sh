#!/bin/bash
#
# build_app.sh
# AndroidMirror
#
# Change Description:
# Author: Nipuna Lakruwan
# Date: 2026-11-02
# Previous Code: Built standard bundle without binary stripping or ad-hoc codesigning.
# Modified Code: Added binary stripping and ad-hoc codesigning for production macOS distribution.
# How: Runs strip -x on release executable and codesign --force --deep --sign - on the installed bundle.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Compiling AndroidMirror (Open Source Edition) in release mode..."
swift build -c release

APP_NAME="Android Mirror.app"
APP_DIR="$SCRIPT_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Creating macOS App Bundle structure: $APP_NAME..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy compiled binary
cp "$SCRIPT_DIR/.build/release/AndroidMirror" "$MACOS_DIR/AndroidMirror"
chmod +x "$MACOS_DIR/AndroidMirror"

# Strip symbols for clean binary
/usr/bin/strip -x "$MACOS_DIR/AndroidMirror" 2>/dev/null || true

# Copy Info.plist
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy AppIcon.icns
if [ -f "$SCRIPT_DIR/AppIcon.icns" ]; then
    echo "==> Installing AppIcon.icns into bundle Resources..."
    cp "$SCRIPT_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "==> Successfully created $APP_NAME at: $APP_DIR"

# Install into /Applications
INSTALL_DIR="/Applications/$APP_NAME"
echo "==> Installing into /Applications..."
rm -rf "$INSTALL_DIR"
cp -R "$APP_DIR" "$INSTALL_DIR"

# Ad-hoc codesign
codesign --force --deep --sign - "$INSTALL_DIR" 2>/dev/null || true
touch "$INSTALL_DIR"

echo "==> Successfully installed to: $INSTALL_DIR"
echo ""
echo "Android Mirror (Open Source Edition by Nipuna Lakruwan) is ready."

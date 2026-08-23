#!/bin/bash
# Builds the SPM executable in release mode and assembles it into a
# double-clickable Overcast.app bundle.
set -euo pipefail

APP_NAME="Overcast"
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"

echo "Quitting any running Overcast instances..."
pkill -f "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" || true

echo "Building release binary..."
swift build -c release

echo "Assembling app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp Info.plist "$APP_DIR/Contents/Info.plist"

echo "Signing app bundle..."
# The binary carries a linker-applied ad-hoc signature scoped to the bare
# Mach-O; once copied into a bundle that no longer matches, and Gatekeeper
# refuses to launch it from Finder. Re-sign the assembled bundle as a whole.
codesign --force --deep --sign - "$APP_DIR"

echo "Done. Run with: open $APP_DIR"

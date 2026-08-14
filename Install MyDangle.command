#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.MyDangleBuild"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/MyDangle.app"

clear
echo "========================================"
echo "        MyDangle 1.5 Physics Installer"
echo "========================================"
echo

if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Xcode command-line build tools were not found."
  echo "Please keep Xcode installed for this one-time build."
  echo
  read -n 1 -s -r -p "Press any key to close..."
  exit 1
fi

echo "Building MyDangle 1.5 with realistic rope physics..."
rm -rf "$BUILD_DIR"

xcodebuild \
  -project "$SCRIPT_DIR/MyDangle.xcodeproj" \
  -scheme MyDangle \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  build

BUILT_APP="$BUILD_DIR/Build/Products/Release/MyDangle.app"

if [ ! -d "$BUILT_APP" ]; then
  echo
  echo "Build completed but MyDangle.app was not found."
  read -n 1 -s -r -p "Press any key to close..."
  exit 1
fi

mkdir -p "$DEST_DIR"
pkill -x MyDangle >/dev/null 2>&1 || true
rm -rf "$DEST_APP"
ditto "$BUILT_APP" "$DEST_APP"

codesign --force --deep --sign - "$DEST_APP" >/dev/null 2>&1 || true
xattr -dr com.apple.quarantine "$DEST_APP" >/dev/null 2>&1 || true

touch "$DEST_APP"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -f "$DEST_APP" >/dev/null 2>&1 || true
fi

echo
echo "Installed successfully:"
echo "$DEST_APP"
echo
echo "Launching MyDangle..."
open -n "$DEST_APP"
sleep 1
open -R "$DEST_APP"

echo
echo "Done. MyDangle 1.5 is installed. Double-click MyDangle.app any time to reopen its control window."
echo
read -n 1 -s -r -p "Press any key to close..."
echo

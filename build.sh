#!/usr/bin/env bash
# Build DropJPG.app (menu bar image→JPG converter) from Sources/main.swift.
set -euo pipefail

cd "$(dirname "$0")"

APP="DropJPG.app"
MACOS="$APP/Contents/MacOS"
RES="$APP/Contents/Resources"

echo "==> Cleaning old bundle"
rm -rf "$APP"
mkdir -p "$MACOS" "$RES"

echo "==> Generating icons"
if [ ! -f Resources/appicon.png ] || [ ! -f Resources/menubar.png ]; then
    swift Sources/gen_icons.swift
fi

echo "==> Building AppIcon.icns"
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
for sz in 16 32 64 128 256 512; do
    sips -z $sz $sz Resources/appicon.png --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
    dbl=$((sz * 2))
    sips -z $dbl $dbl Resources/appicon.png --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$RES/AppIcon.icns"

echo "==> Copying menu bar icons"
cp Resources/menubar.png "$RES/menubar.png"
cp Resources/menubar@2x.png "$RES/menubar@2x.png"

echo "==> Compiling Swift"
swiftc -O -o "$MACOS/DropJPG" Sources/main.swift -framework Cocoa

echo "==> Writing Info.plist"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>DropJPG</string>
    <key>CFBundleDisplayName</key>     <string>DropJPG</string>
    <key>CFBundleIdentifier</key>      <string>com.eternaxcode.dropjpg</string>
    <key>CFBundleVersion</key>         <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleExecutable</key>      <string>DropJPG</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>  <string>12.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

echo "==> Ad-hoc codesign"
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "   (codesign skipped)"

echo "==> Done: $APP"
echo "    Run:  open $APP    (icon appears in the menu bar)"

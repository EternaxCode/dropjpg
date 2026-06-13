#!/usr/bin/env bash
# Build DropJPG.app then package it into a distributable DMG.
# Output: dist/DropJPG.dmg  (drag-to-Applications layout)
set -euo pipefail

cd "$(dirname "$0")"

APP="DropJPG.app"
VOL="DropJPG"
DMG="dist/DropJPG.dmg"

echo "==> Building app"
./build.sh

echo "==> Staging DMG contents"
STAGE="$(mktemp -d)/dmg"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"   # drag-to-install target
# Bundle the unquarantine helper + a short read-me so users aren't stuck on Gatekeeper.
cp scripts/install.command "$STAGE/먼저 실행 - 설치도우미.command" 2>/dev/null || true
chmod +x "$STAGE/먼저 실행 - 설치도우미.command" 2>/dev/null || true

echo "==> Creating DMG"
mkdir -p dist
rm -f "$DMG"
hdiutil create -volname "$VOL" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

echo "==> Done: $DMG"
hdiutil verify "$DMG" >/dev/null && echo "    verified OK"
ls -lh "$DMG"

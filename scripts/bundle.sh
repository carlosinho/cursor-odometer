#!/bin/zsh
# Builds a release binary and assembles CursorOdometer.app next to this repo's build directory.
# Usage: scripts/bundle.sh [--open]
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="CursorOdometer"
BUNDLE_ID="com.local.cursor-odometer"
OUT="build/$APP_NAME.app"
ICON_SRC="Resources/app-icon.png"

VERSION="$(sed -n 's/.*static let short = "\([^"]*\)".*/\1/p' Sources/CursorOdometer/AppVersion.swift)"
[[ -n "$VERSION" ]] || { echo "Could not read version from AppVersion.swift" >&2; exit 1; }

swift build -c release --product "$APP_NAME"
BIN="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$OUT"
mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"
cp "$BIN" "$OUT/Contents/MacOS/$APP_NAME"

ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -s format png -z $size $size "$ICON_SRC" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -s format png -z $((size * 2)) $((size * 2)) "$ICON_SRC" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$OUT/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

cat > "$OUT/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleName</key><string>Cursor Odometer</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$OUT"
echo "Built $OUT"
[[ "${1:-}" == "--open" ]] && open "$OUT" || true

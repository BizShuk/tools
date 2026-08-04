#!/usr/bin/env bash
# Builds MacTrans.app (the Services provider) and the mactrans CLI.
# Output: .build/MacTrans.app and .build/release/mactrans
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP="$ROOT/.build/MacTrans.app"
BUNDLE_ID="com.shuk.transzh"

swift build -c release --product MacTransService
swift build -c release --product mactrans

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/release/MacTransService" "$APP/Contents/MacOS/MacTransService"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Ad-hoc signature. Notification Center and the Services registry both refuse to
# deal with an unsigned bundle, so this is required even for a local-only tool.
codesign --force --sign - --identifier "$BUNDLE_ID" "$APP"
codesign --verify --verbose=1 "$APP"

echo "built: $APP"
echo "built: $ROOT/.build/release/mactrans"

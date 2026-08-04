#!/usr/bin/env bash
# Removes MacTrans.app, its service registration, and the CLI symlink.
set -euo pipefail

DEST="$HOME/Applications/MacTrans.app"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

pkill -f "MacTrans.app/Contents/MacOS/MacTransService" 2>/dev/null || true
[ -d "$DEST" ] && "$LSREGISTER" -u "$DEST" || true
rm -rf "$DEST"
rm -f "$HOME/.local/bin/mactrans"
/System/Library/CoreServices/pbs -update 2>/dev/null || true

echo "已移除 MacTrans.app 與 mactrans CLI。"

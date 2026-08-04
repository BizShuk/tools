#!/usr/bin/env bash
# Installs MacTrans.app into ~/Applications, registers its system service,
# and links the mactrans CLI into ~/.local/bin.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/Applications/MacTrans.app"
BIN_DIR="$HOME/.local/bin"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

"$ROOT/scripts/build.sh"

# A running copy holds the old service port; replacing the bundle underneath it
# leaves a stale registration that answers with the previous binary.
pkill -f "MacTrans.app/Contents/MacOS/MacTransService" 2>/dev/null || true

mkdir -p "$HOME/Applications" "$BIN_DIR"
rm -rf "$DEST"
cp -R "$ROOT/.build/MacTrans.app" "$DEST"

ln -sf "$ROOT/.build/release/mactrans" "$BIN_DIR/mactrans"

"$LSREGISTER" -f -R "$DEST"
/System/Library/CoreServices/pbs -update 2>/dev/null || true

# First launch is what publishes the service and prompts for notifications.
open -g "$DEST"

cat <<'EOF'

已安裝：
  ~/Applications/MacTrans.app   （背景服務，無 Dock 圖示）
  ~/.local/bin/mactrans         （CLI）

接下來手動做兩件事：
  1. 允許通知：首次翻譯時系統會詢問，或到
     系統設定 › 通知 › MacTrans 開啟。
  2. （選用）設快捷鍵：系統設定 › 鍵盤 › 鍵盤快速鍵 › 服務 ›
     文字 › 「翻譯成繁體中文」，勾選並指定快捷鍵。

用法：在任何 App 選取文字 → 右鍵 › 服務 › 翻譯成繁體中文
EOF

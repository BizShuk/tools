# mactrans

在 macOS 任何 App 選取文字，右鍵 › 服務 › **翻譯成繁體中文**，翻譯結果以通知呈現。
原文不會被更動。

## 為什麼用它

macOS 內建的 Translation 引擎（Apple Translate 背後那顆）品質好、完全離線、免 API
key，但系統只在 Safari、備忘錄等少數 App 暴露翻譯介面。mactrans 把同一顆引擎接到
**全系統的 Services 選單**，任何能選取文字的 App 都能用。

## 怎麼開始

```bash
./scripts/install.sh
```

安裝腳本會建置、簽章、安裝到 `~/Applications/MacTrans.app`，並把 CLI 連到
`~/.local/bin/mactrans`。首次啟動會跳出通知授權提示 —— **必須按「允許」**。

接著（選用）到 系統設定 › 鍵盤 › 鍵盤快速鍵 › 服務 › 文字，
替「翻譯成繁體中文」指定一組快捷鍵。

## 怎麼用

**Services 選單**：任何 App 選取文字 → 右鍵 › 服務 › 翻譯成繁體中文 →
通知顯示譯文，點通知上的「複製翻譯」把譯文放進剪貼簿。

**CLI**：

```bash
mactrans "Ship it before Friday."          # 引數
pbpaste | mactrans                          # stdin
mactrans -v -t ja "把這句翻成日文"           # 指定目標語言、顯示偵測結果
```

## 支援範圍

來源語言取決於系統已下載的翻譯語言包（系統設定 › 一般 › 語言與地區 › 翻譯語言）。
未下載的語言會明確報錯，不會靜默失敗。

簡體中文走 ICU 字形轉換而非翻譯引擎（Apple 不支援中文↔中文），因此只轉字形、
不做台灣用語在地化：`計算機` 不會變成 `電腦`。

技術脈絡、模組邊界與關鍵決策見 [CLAUDE.md](CLAUDE.md)。

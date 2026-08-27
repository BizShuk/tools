# Tools — macOS 工具整合插件 (macOS Tool Integration Plugin)

提供 Apple 原生應用程式的 CLI 技能，統一由既有工具操作使用者資料：

| 技能 (Skill) | CLI | 用途 |
| :--- | :--- | :--- |
| `apple-calendar` | `accli` | 行事曆事件與空檔查詢 |
| `apple-email` | `email` | Apple Mail 郵件讀寫與整理 |
| `apple-notes` | `notes` | Apple Notes 筆記與資料夾管理 |
| `apple-reminders` | `remindctl` | 提醒事項與清單管理 |

`apple-calendar` 與 `apple-reminders` 由分類層的 `skills/` 提供；
`apple-email` 與 `apple-notes` 分別由 `macemailapp/` 與 `macnotesapp/` submodule 提供。

以及本分類其他工具的 CLI 技能：

| 技能 (Skill) | CLI | 用途 | 來源 |
| :--- | :--- | :--- | :--- |
| `autop` | `autop` | 單一入口啟動本機 LLM CLI | `autop/` |
| `img` | `img` | 圖片格式轉換、尺寸調整與影像屬性檢視 | `img/` |
| `mdserver` | `mdserver` | 本機 Markdown 目錄預覽伺服器 | `mdserver/` |
| `pm2` | `pm2` | 常駐程序、cron 任務與日誌管理 | `pm2/` |
| `cleaning-vscode-forks` | — | 清理 VS Code fork 的記憶體與磁碟佔用 | `skills/` |

## 專案清單 (Projects)

`tools/` 同時是 21 個獨立工具 repo 的分類容器 (git submodule)。每個專案自帶統一介面 (README.md / CLAUDE.md / AGENTS.md / README.todo / docs/)；一句話用途取自各專案 README 第一段。

| 專案 (Project) | 一句話用途 (Purpose) | 主要技術 (Tech) | 型態 (Type) |
| :--- | :--- | :--- | :--- |
| `auth` | agentsdk 家族的 LLM provider 認證模組 | Go | submodule |
| `autop` | 單一入口啟動已設定的本機 LLM CLI (claude / codex / grok 等) | Go (cobra) | submodule |
| `dux` | 高效能單次磁碟空間分析器 | Go (gosdk) | submodule |
| `go-dependency-analysis` | 只讀、純標準庫的 Go workspace 依賴圖檢視 CLI | Go | submodule |
| `gx` | 免 API key 從公開網頁擷取結構化識別資訊的通用 CLI | Go | submodule |
| `img` | webp / jpg / png 互轉、尺寸調整與只讀檔頭的影像屬性報告 | Go (gosdk) | submodule |
| `macemailapp` | Apple Mail.app 的 CLI 與 Python 函式庫 (`email`) | Python | submodule |
| `macnotesapp` | Apple Notes 的 ID-first CLI 與函式庫 (`notes`, RhetTbull fork) | Python | submodule |
| `mactrans` | macOS 服務選單「翻譯成繁體中文」, 結果以通知呈現 | Swift / Shell | submodule |
| `mdserver` | 本機 Markdown 目錄預覽伺服器 | Go | submodule |
| `pm2` | Go 實作的 PM2 風格 process manager (自動重啟、cron、TUI) | Go | submodule |
| `port` | 檢查連接埠狀態、監聽進程並匯出監控指標的 CLI | Go | submodule |
| `proxy` | 通用 LLM API 轉譯代理 (CLI 客戶端 ↔ 多家上游 provider) | Go | submodule |
| `sandbox` | 手動建立 process sandbox 的操作文件集 (`srt` wrapper 與 Claude Code sandbox) | Docs | submodule |
| `sessiond` | 跨 agent session 摘要 ingestor (由 Claude Code / Codex lifecycle hook 觸發) | Go | submodule |
| `skills-cli` | Go 重寫的 `skills add [path]` 命令列工具 (submodule name 為 `skills`) | Go | submodule |
| `trans` | local-first 語言轉換工具, 同一組 CLI 與 SDK 介面 | Go | submodule |
| `video-utils` | ffmpeg 媒體前處理的獨立 Go module | Go | submodule |
| `voice` | Apple MLX 上的 Qwen3-ASR 終端機語音轉錄 demo | Go + Python (MLX) | submodule |
| `vscoed-plugin` | 單一 VS Code extension 承載多個獨立功能模組 | TypeScript | submodule |
| `ytdl` | 將 YouTube URL 下載為 mp3 / mp4 的單一用途 CLI | Go | submodule |

專案間無 build-time 相依 (`auth` 為 agentsdk 家族的模組, 由 `ai/agentSDK` 端消費); 每個 submodule 以
`git submodule update --init <name>` 取得。

## 安裝與使用 (Installation and Usage)

此插件為獨立 GitHub repo（`bizshuk/tools`），可由任一 Claude Code
marketplace 以 github source 引用：

```json
{
  "name": "tools",
  "source": { "source": "github", "repo": "bizshuk/tools" }
}
```

本地技能由 `skills/` 自動探索；`hooks`／`agents`／`output-styles`
亦由 Claude Code plugin loader 自動發現，不在 manifest 重複列舉。
各技能只在對應 Apple 應用操作或使用者明確要求時觸發；實際 CLI 的權限
與安全守衛以各自 `SKILL.md` 為準。

repo 結構、submodule 機制與分類層慣例見 [CLAUDE.md](CLAUDE.md)。

# CLAUDE.md — mactrans 技術脈絡

業務定義見 [README.md](README.md)。本檔只放邊界、擁有權與關鍵決策。

## 結構

```tree
mactrans/
├── Package.swift                  # SPM，platform macOS 26
├── Resources/Info.plist           # app bundle 的 Info.plist（NSServices 宣告在這）
├── Sources/
│   ├── TranslateCore/             # 翻譯領域，不依賴 AppKit
│   │   ├── Translator.swift       # 入口：偵測 → 路由 → 翻譯
│   │   ├── LanguageDetector.swift # NLLanguageRecognizer，限制在引擎支援語言內
│   │   ├── ChineseScriptConverter.swift  # 簡→繁 ICU transform
│   │   └── TranslateError.swift   # 所有失敗模式與使用者可讀訊息
│   ├── mactrans/CLI.swift         # CLI 前端
│   └── MacTransService/           # app bundle，唯一依賴 AppKit 的地方
│       ├── AppMain.swift          # NSApplication + servicesProvider 註冊
│       ├── ServiceProvider.swift  # Services 選單 → TranslateCore
│       └── Notifier.swift         # 通知呈現與授權處理
└── scripts/{build,install,uninstall}.sh
```

擁有權：翻譯行為（語言路由、錯誤語意）全部屬於 `TranslateCore`；`MacTransService`
只負責取得文字與呈現結果，不做任何語言判斷。CLI 與 app 共用同一顆 core，兩者行為
差異只該來自呈現層。

## 關鍵決策

**用 `Translation.framework`，不用 `FoundationModels`。**
兩者都在 macOS 26 內建。`FoundationModels` 的通用模型對普通英文散文會觸發
`guardrailViolation`（實測："The quick brown fox…" 這類句子即被擋），且翻譯品質明顯
較差。`Translation.framework` 是專用翻譯模型，無 guardrail、速度約 1–2 秒。

**`TranslationSession(installedSource:target:)` 讓 core 不需要 SwiftUI。**
一般文件示範的是 SwiftUI `.translationTask` modifier。該 convenience init 讓純 CLI 也能
呼叫，代價是語言包必須已下載 —— 未下載時 `LanguageAvailability.status` 回報
`.supported`，我們轉成明確錯誤訊息而非嘗試下載（下載 UI 只有 SwiftUI 路徑有）。

**中文↔中文走 ICU，不走翻譯引擎。**
`LanguageAvailability.status(from: zh-Hans, to: zh-Hant)` 實測回報 `unsupported`。
因此簡體來源改用 `CFStringTransform` 的 `Simplified-Traditional`。這是字形轉換，
不做地區用語替換。

**Bundle identifier 是 `com.shuk.transzh`，與產品名 MacTrans 不一致 —— 這是刻意的。**
通知授權綁在 bundle id 上。開發期間若在授權提示顯示中終止 app，系統會記下永久
`denied`，而該記錄存在 `~/Library/Group Containers/group.com.apple.usernoted/db2/db`，
沒有 Full Disk Access 無法清除，且此狀態下 app 不會出現在系統設定的通知清單裡，
使用者無從重新開啟。`tw.bizshuk.mactrans`、`tw.bizshuk.MacTrans`、`tw.bizshuk.transzh`
三個 id 都在開發中被這樣污染，只能換新 id。
**改動 bundle id 或重啟 agent 前，先確認沒有授權提示正在顯示。**

**Services 註冊靠 Info.plist 的 `NSServices`，不靠 Automator workflow。**
`NSMessage` 的值必須與 `ServiceProvider` 的 selector 名稱一致；改其中一邊而不改
另一邊會靜默失效（選單項目還在，點了沒反應）。

## 驗證

```bash
mactrans -v "text"                     # core 路徑，最快的迴圈
./scripts/install.sh                   # 建置 + 簽章 + 註冊
/System/Library/CoreServices/pbs -dump_pboard | grep -A12 transzh   # 確認服務已註冊
log stream --predicate 'subsystem == "com.shuk.transzh"'          # app 端診斷
```

`MacTransService --selftest <text>` 可跳過 Services 層直接跑「翻譯 → 通知」。
`NSPerformService` 無法用來自動化驗證：實測對 Apple 自家服務也一律回傳 `false`。

## 依賴

只有系統框架：`Translation`、`NaturalLanguage`、`AppKit`、`UserNotifications`、`OSLog`。
無第三方套件，無網路存取。

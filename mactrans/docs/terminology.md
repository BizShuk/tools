# 術語表 (Terminology)

| 術語 | 定義 |
| --- | --- |
| Services 選單 | macOS 的系統服務選單。App 在 Info.plist 宣告 `NSServices` 即可對全系統提供動作，使用者從右鍵選單或 系統設定 › 鍵盤 › 鍵盤快速鍵 › 服務 存取。 |
| `NSMessage` | `NSServices` 條目中的欄位，值是提供者物件上的 Objective-C selector 名稱（不含 `:userData:error:` 部分）。 |
| `NSPortName` | 服務提供者 app 的識別名稱。`NSPerformService` 的路徑格式為 `<NSPortName>/<選單標題>`。 |
| Translation framework | macOS 15+ 的系統翻譯 API，Apple Translate 使用的同一顆離線模型。本專案的翻譯來源。 |
| FoundationModels | macOS 26 的通用端上語言模型 API（Apple Intelligence）。**本專案不使用**，原因見 CLAUDE.md。 |
| 語言包 (language pack) | 單一語言對的離線翻譯模型。由 系統設定 › 一般 › 語言與地區 › 翻譯語言 管理。未下載時 `LanguageAvailability.status` 回報 `.supported` 而非 `.installed`。 |
| `installed` / `supported` / `unsupported` | `LanguageAvailability.Status` 的三個值：可立即翻譯／引擎支援但語言包未下載／引擎沒有這個語言對。 |
| 字形轉換 (script conversion) | 簡體↔繁體的字元對應，由 ICU `Simplified-Traditional` transform 執行。與翻譯不同，不處理地區用語差異。 |
| LSUIElement | Info.plist 旗標，令 app 不出現在 Dock 與 App 切換器。MacTrans.app 是這類背景 agent。 |
| ad-hoc 簽章 | `codesign --sign -`，無開發者憑證的本機簽章。Services 註冊與通知都要求 bundle 已簽章。 |
| 授權污染 | 本專案自用詞：bundle id 被系統記下永久 `denied` 通知授權，且無 Full Disk Access 無法清除。見 CLAUDE.md。 |

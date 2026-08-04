# 2026-08-01 — 選擇翻譯引擎與通知授權踩雷

## 背景

需求：在 macOS 任何 App 選取文字，右鍵翻成繁體中文，以通知呈現。
機器：macOS 26.5、Xcode 26.5 SDK、Apple Intelligence 已啟用。

## 決策一：FoundationModels 出局

先試 `FoundationModels`（Apple Intelligence 端上通用模型），兩個問題：

1. **翻譯品質差。** "The quick brown fox jumps over the lazy dog" 被譯成
   「快笨的貓頭鷹跳過懶惰的狗」。
2. **guardrail 誤擋。** 改用 `@Generable` guided generation 消除前綴後，同一段
   Kubernetes 說明文字直接拋 `GenerationError.guardrailViolation`
   （"Response may contain sensitive or unsafe content"）。翻譯工具吃的是任意輸入，
   隨機被擋等於不可用。

改用 `Translation.framework` —— Apple Translate 背後的專用模型。無 guardrail、
1–2 秒、品質正常。

意外收穫：`TranslationSession(installedSource:target:)` 是 public convenience init，
不需要 SwiftUI `.translationTask` modifier，純 CLI 就能呼叫。代價是語言包必須已下載。

實測 `LanguageAvailability.status(from: zh-Hans, to: zh-Hant)` 回報 `unsupported` ——
Apple 不做中文↔中文，改用 ICU `CFStringTransform` 的 `Simplified-Traditional`。

## 決策二：Services provider app，不是 Automator workflow

用 app bundle 的 `NSServices` Info.plist 宣告 + `NSApp.servicesProvider`，
比手刻 Automator `.workflow` plist 可控。註冊靠 `lsregister -f -R` + `pbs -update`，
驗證用 `pbs -dump_pboard | grep <bundle-id>`。

## 踩雷：通知授權被永久污染

`UNUserNotificationCenter` 的授權綁 bundle id。開發時我在授權提示顯示中
`pkill` 了 app，系統就記下 `authorizationStatus = .denied(1)`。

- 該記錄在 `~/Library/Group Containers/group.com.apple.usernoted/db2/db`，
  受 TCC 保護，沒有 Full Disk Access 讀不到也清不掉。
- `~/Library/Preferences/com.apple.ncprefs.plist` **沒有**對應條目，因此 app 也
  不會出現在 系統設定 › 通知 清單裡 —— 使用者無從手動重新開啟。
- `killall usernoted`、重新簽章、`lsregister` 重註冊都無效。

`tw.bizshuk.mactrans`、`tw.bizshuk.MacTrans`、`tw.bizshuk.transzh` 三個 id 都因此報廢
（第三個是提示還掛在畫面上時就改名重裝），最終改用 `com.shuk.transzh`。
**規則：授權提示顯示期間不得終止 app，也不得改 bundle id 重裝。**

## 踩雷：NSPerformService 無法用於自動化驗證

想用 `NSPerformService("MacTrans/翻譯成繁體中文", pboard)` 驗證服務可被呼叫，
一律回傳 `false`。對照組測 Apple 自家的
`ChineseTextConverterService/Convert Text to Full Width` 同樣 `false`，
確認是呼叫端限制而非服務本身有問題。

改為在 app 內加 `--selftest <text>` 旗標，跳過 Services 層直接跑
「翻譯 → 通知」。LaunchServices 啟動時不帶引數，因此正常使用時無作用。

附帶：LaunchServices 啟動的 app 沒有可用的 stdio，診斷改走 `OSLog`
（`log stream --predicate 'subsystem == "com.shuk.transzh"'`）。

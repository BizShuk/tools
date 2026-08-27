# img — 圖片轉換與檢視 CLI

## Context

`~/projects/tools/` 底下有 20 個獨立工具 repo, 但`沒有任何圖片處理工具`. 目前要看一張圖的
尺寸或格式得靠 `sips` / `file` / Python, 要轉檔得靠 `cwebp` / ImageMagick — 都是外部相依,
且輸出格式不利 AI 解析.

本計畫建立 `img`: 一支 Go CLI, 兩個子命令 (`convert` / `analyze`), 以 `bizshuk/gosdk` 為
設定與命令骨架, 發佈成 public repo `bizshuk/img`, 掛回 `tools/` 成為 submodule, 並附一份
skill 讓 AI 知道怎麼用它 (特別是 `analyze --json`).

`零外部二進位相依`是硬性目標 — WebP 編解碼走純 Go 路徑, 不裝 libwebp 也能跑.

## 決策 (Decisions)

| 項目 | 選擇 | 理由 |
| --- | --- | --- |
| WebP 編解碼 | `github.com/gen2brain/webp` v0.6.4 | 唯一同時支援 lossy+lossless `encode` 且免 cgo 的選項. 有系統 libwebp 時經 purego dlopen 走快路徑, 沒有時 fallback 到內建 wasm2go 轉譯的純 Go 實作. 僅一個相依 `ebitengine/purego`. (`x/image/webp` 只能 decode; `nativewebp` 只能 lossless encode) |
| 縮放演算法 | `golang.org/x/image/draw` 的 `CatmullRom` | 官方套件, 品質足夠, 不引入 `disintegration/imaging` (已停止維護) |
| 格式偵測 | `image.DecodeConfig` 的 magic-byte sniffing | 不看副檔名. jpeg/png 由 stdlib 註冊, webp 由 gen2brain 的 `init()` 註冊 |
| JPEG EXIF orientation | 自寫最小 APP1/TIFF 解析 (~60 行, 純 stdlib) | 只為了一個 tag 拉進 `go-exif` (體積大) 或 `goexif` (已封存) 不划算. WebP 的 orientation 直接用 lib 的 `DecodeExif` |
| 二進位體積 | 預期 10–15 MB | wasm2go 的 `libwebp.go` 有 2.7 MB 原始碼. 換來零外部相依, 接受 |

## 檔案結構 (Repo Layout)

新 repo `bizshuk/img`, module path `github.com/bizshuk/img`, 照 `port` submodule 的骨架:

```tree
img/
├── main.go                      # config.Default() -> cmd.Execute()
├── cmd/
│   ├── root.go                  # RootCmd + gosdkcmd.ConfigCmd / VersionCmd
│   ├── convert.go               # convert 子命令與旗標
│   └── analyze.go               # analyze 子命令與旗標
├── config/
│   ├── config.go                # gosdk config.Default(WithAppName("img"), WithDefaultValue(...))
│   └── default_settings.json    # quality / method / mode / log_level 預設
├── svc/
│   ├── format.go                # Format 列舉, magic-byte 偵測, 副檔名對應
│   ├── codec.go                 # Decode / Encode 分派 (jpeg, png, webp)
│   ├── exif.go                  # 最小 orientation 讀取 + 套用旋轉
│   ├── resize.go                # fit / cover / exact 三種模式
│   ├── analyze.go               # Info struct + Inspect(io.Reader)
│   └── convert.go               # pipeline: decode -> autorotate -> resize -> encode
├── skills/img/SKILL.md          # 給 AI 的使用說明
├── docs/terminology.md
├── docs/memory/
├── README.md CLAUDE.md AGENTS.md(symlink) README.todo package.json .gitignore LICENSE
```

`參考檔案:` [port/main.go](file:///Users/shuk/projects/tools/port/main.go),
[port/cmd/root.go](file:///Users/shuk/projects/tools/port/cmd/root.go),
[port/config/config.go](file:///Users/shuk/projects/tools/port/config/config.go),
[port/package.json](file:///Users/shuk/projects/tools/port/package.json) — 逐一照抄骨架後改內容.

## CLI 介面 (Interface)

### `img convert`

```bash
img convert <path>... -f <format> [flags]
```

- 輸入接受`多個檔案路徑`, 也接受`目錄` (非遞迴, 只掃該層可辨識的圖檔).
- `-f, --format`  目標格式: `webp` | `jpg` | `png` (必填).
- `-o, --output`  目錄時逐檔輸出並沿用原檔名換副檔名; 檔名時只允許單一輸入. 未給則寫在原檔旁.
- `-w, --width` / `-H, --height` / `--scale`  尺寸調整, 三者可組合出下列語意.
- `--mode`  `fit` (預設, 等比縮入框內) | `cover` (填滿後置中裁切) | `exact` (強制拉伸變形).
- `--upscale`  預設`不放大`; 目標大於原圖時維持原尺寸, 加此旗標才放大.
- `-q, --quality`  1–100, 對 jpg 與 lossy webp 生效 (預設由 settings.json 給).
- `--lossless`  webp 專用.
- `--no-auto-rotate`  預設會依 EXIF orientation 轉正後再輸出 (手機照片轉檔不轉正是實質錯誤).
- `--overwrite`  預設拒絕覆寫已存在的輸出檔.

### `img analyze`

```bash
img analyze <path>... [--json]
```

只解析 header, `不解碼整張圖`. 輸出欄位: 檔名, 格式 (magic bytes 判定), 寬 x 高, 總像素數,
長寬比 (約分), color model, bit depth, 是否有 alpha, EXIF orientation, WebP 動畫張數, 檔案大小.
副檔名與實際格式不符時額外標示 `mismatch`.

`--json` 輸出陣列, 供 AI 與腳本消費 — skill 一律引導走這條.

## gosdk 整合 (gosdk Integration)

- `go.mod` 釘 `github.com/bizshuk/gosdk v1.3.14` (現行最新).
- `config/config.go` 呼叫 `config.Default(WithAppName("img"), WithDefaultValue(defaultSettingsJSON))`
  → 設定根目錄固定 `~/.config/img/`, 首次執行自動落 `settings.json`.
- settings 一律`扁平 SCREAMING_SNAKE key` (`QUALITY`, `WEBP_METHOD`, `RESIZE_MODE`, `LOG_LEVEL`),
  才能被 `APP_QUALITY` 這類環境變數覆寫; 巢狀 key 無法從 env 覆寫.
- 命令列旗標優先於 settings; 未給旗標時取 viper 值.
- `RootCmd` 掛上 `gosdkcmd.ConfigCmd` 與版本子命令, 讓 `img config show` 直接可用.
- 錯誤與警告用 `slog` 結構化輸出, 每筆至少帶檔案路徑與失敗原因.

## 測試 (Tests)

單元測試就地產生測試圖 (`image.NewRGBA` + 各 encoder 寫進 `bytes.Buffer`), `不放二進位 fixture`:

- `svc/format_test.go` — 三種格式的 magic bytes 判定; 副檔名說謊時仍判對.
- `svc/resize_test.go` — fit/cover/exact 三模式的輸出尺寸; 不放大預設行為.
- `svc/convert_test.go` — 九種 format 兩兩轉換的 round-trip, 確認尺寸與格式.
- `svc/exif_test.go` — 手工組 APP1 位元組, 驗證八個 orientation 值與缺 EXIF 的情形.
- `svc/analyze_test.go` — Info 欄位正確性, 含 alpha 判定.
- `cmd/convert_test.go` — 目錄輸入, 多檔輸出命名, 拒絕覆寫.

## 落地步驟 (Landing Steps)

1. `gh repo create bizshuk/img --public` (owner 一律小寫 `bizshuk`; 名稱已確認未被佔用).
2. 在 `~/projects/tools/img/` 建立骨架與 `go.mod`, 先讓 `img analyze` 端到端可跑 (最小可用版).
3. 疊上 `convert` 的格式轉換 (不含 resize), 再疊 resize 三模式, 最後疊 EXIF 轉正.
4. 補齊統一介面文件: `README.md` (業務定義), `CLAUDE.md` (技術脈絡), `AGENTS.md` symlink,
   `README.todo`, `docs/terminology.md`, `docs/memory/`, `package.json` (dev/test/build/deploy/lint/clean).
5. 寫 `skills/img/SKILL.md`: 何時觸發, 兩個子命令的旗標表, `--json` 欄位說明, 常見情境
   (壓縮出網頁用 WebP, 批次縮圖, 確認實際格式), 以及`不要`用它做的事 (不做內容/色彩分析).
6. commit + push 到 `bizshuk/img`.
7. 回到 `tools/`: `git submodule add https://github.com/bizshuk/img.git img`,
   在 [README.md](file:///Users/shuk/projects/tools/README.md) 的技能表與專案清單各補一列,
   在 [CLAUDE.md](file:///Users/shuk/projects/tools/CLAUDE.md) 把 submodule 數 20 改 21,
   在 [.claude-plugin/plugin.json](file:///Users/shuk/projects/tools/.claude-plugin/plugin.json)
   的 `skills` 陣列加 `bizshuk/img`, 在 `.gitignore` 補 `img/bin/`, `img/tmp/`.
8. `tools/` 一併提交 — 分類層有背景程序會自動 commit+push 未提交變更, 完成即提交, 不留過夜.

## 驗證 (Verification)

```bash
cd ~/projects/tools/img
npm run lint && npm run test          # gofmt + go vet + go test ./...
npm run build                         # bin/img

# 端到端: 造一張含 alpha 的 PNG, 走完三種格式
go run . analyze testdata_out/a.png --json
go run . convert testdata_out/a.png -f webp -w 800 -o /tmp/img-smoke/
go run . analyze /tmp/img-smoke/a.webp --json | jq '.[0] | {format, width, height}'
# 預期: format=="webp", width==800, height 依原比例

# cover 模式應剛好等於指定框
go run . convert testdata_out/a.png -f jpg -w 400 -H 400 --mode cover -o /tmp/img-smoke/
go run . analyze /tmp/img-smoke/a.jpg --json | jq '.[0] | {width, height}'   # 400 x 400

# 免外部相依驗證: 確認沒 dlopen 系統 libwebp 也能編出 webp
go test ./svc/ -run WebP -tags nodynamic

# 副檔名說謊時 analyze 要抓出來
cp /tmp/img-smoke/a.webp /tmp/img-smoke/liar.png
go run . analyze /tmp/img-smoke/liar.png     # 應顯示 format=webp 並標 mismatch
```

`submodule 驗證:` 在 `tools/` 跑 `git submodule status img` 應列出 gitlink,
`gh api repos/bizshuk/img --jq .visibility` 應回 `public`.

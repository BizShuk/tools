# tools/ — 技術脈絡 (Technical Context)

本檔記錄本分類的目錄結構、submodule 機制與慣例。技能清單與安裝方式由
[README.md](README.md) 單一擁有，本檔不重複。

## 目錄結構 (Directory Layout)

```tree
tools/
├── README.md                     # 插件說明與技能清單
├── CLAUDE.md                     # 本檔
├── AGENTS.md -> CLAUDE.md        # 軟連結
├── .gitmodules                   # 23 個 submodule 的 path / url / branch
├── .gitignore                    # 逐 submodule 列出的建置產物忽略清單
├── .claude-plugin/               # marketplace.json (唯一 manifest, 無 plugin.json)
├── skills/                       # 分類層自有技能 (3 個)
├── .claude/skills/               # 分類層之外另一份技能探索路徑
├── .agents/skills/ .grok/skills/ # 同上, 供其他 agent 工具探索
├── .vscode/                      # 目前為空目錄
└── <23 個 submodule 目錄>        # 各自獨立的 repo, 見 .gitmodules
```

## Submodule 機制 (Submodule Mechanics)

本分類 repo 的 `origin` 是 `BizShuk/tools`。23 個專案全部以 git submodule 掛載，
`目前全部已初始化`。

取得單一專案：

```bash
git submodule update --init <name>
```

一次取得全部：

```bash
git submodule update --init --recursive
```

`未初始化的 submodule：` 無 (None)。

### 命名注意 (Naming Caveat)

`.gitmodules` 有一組 name 與 path 不一致的 entry：

| submodule name | path | url |
| --- | --- | --- |
| `skills` | `skills-cli` | `github.com/BizShuk/skills.git` |

因此 `git submodule update --init skills-cli` 與 `git submodule update --init skills`
`都可能`被接受（前者比對 path，後者比對 name），但 `skills` 這個字在本分類還同時指
`tools/skills/` 這個`非 submodule`的技能目錄。討論時請一律用 `skills-cli` 指該
submodule，用 `skills/` 指分類層技能目錄。

## 分類層慣例 (Category Conventions)

- 每個專案`自帶完整的 unified interface`；分類層`不放程式碼`。
- 分類層文件只做導覽（`README.md`）與結構說明（本檔）。專案清單、技能表與安裝方式
  由 `README.md` 擁有，本檔一行指過去，不複製。
- 新增工具：建立獨立 repo → `git submodule add` → 在 `README.md` 補一列 →
  若要暴露成技能，於 `.claude-plugin/marketplace.json` 的 `plugins` 陣列
  補一個 github source 條目即可；`不要`同時寫進 `tools` 的 `skills`。
- submodule 內的變更`在該 submodule 內 commit 與 push`；分類層只記錄 gitlink。
- 分類層不對 submodule 做跨 repo 的批次建置；各專案的指令見各自 `package.json`。

## 分類層自身檔案 (Category-Level Files)

### `.claude-plugin/marketplace.json`

本分類`只有這一份 manifest`，`沒有 plugin.json`。它把 repo 自身宣告成 marketplace
（`name: bizshuk-tools`），`plugins` 陣列有`兩類`條目，`職責不重疊`：

- `tools`（`source: "./"`）—— 本 repo 自身。它的 `skills` 只有 `./skills` 一條，
  `僅負責分類層自有技能`。
- 九個 `github source` 條目 —— 每個帶技能的 submodule `各自是一個 plugin`，
  由它自己的 repo 提供技能。

`submodule 技能不在 tools.skills 裡`。既然該 submodule 已被定址成獨立 plugin，
再列一次 `./<submodule>/skills/<skill>` 就是同一個技能的第二份宣告，
`會重複偵測`（實測從 10 個膨脹成 17 個）。一個技能只由一處擁有。

規則是`凡 submodule 內有 SKILL.md, 就在 plugins 陣列補一個 github source 條目`，
目前九項：

| 技能 | submodule plugin | repo |
| --- | --- | --- |
| `autop` | `autop` | `bizshuk/autop` |
| `disk-analyze` | `dux` | `bizshuk/dux` |
| `img` | `img` | `bizshuk/img` |
| `apple-email` | `macemailapp` | `bizshuk/macemailapp` |
| `apple-notes` | `macnotesapp` | `bizshuk/macnotesapp` |
| `mdserver` | `mdserver` | `bizshuk/mdserver` |
| `pm2` | `pm2` | `bizshuk/pm2` |
| `imagine` | `proxy` | `bizshuk/proxy` |
| `migrate-from-ytdl` | `vdl` | `bizshuk/vdl` |

`imagine` 在 `proxy` 內`不在慣例位置`（埋在 `plugins/proxy-imagegen/skills/` 底下），
但因為整個 repo 交給 submodule 自己掃，這裡不必知道它的路徑。

`macemailapp/tmp/SKILL.md` 是一份殘留的 `apple-notes` 複本，`不是技能`，
應在該 submodule 內刪除。

`取得來源的後果：`submodule 技能`一律從各自 repo 的遠端取得`，不讀本機工作目錄。
因此`submodule 內尚未 push 的技能改動不會生效`，要先在該 submodule push。
好處是安裝端`不需要 submodule`——marketplace 安裝只做 plain clone，本機路徑本來就會落空。

### `skills/`

分類層自有技能三個：`apple-calendar`、`apple-reminders`、`cleaning-vscode-forks`。
`apple-email` 與 `apple-notes` 雖列在 `README.md` 的技能表，但`不在此目錄`——它們
分別由 `macemailapp/skills/` 與 `macnotesapp/skills/` 提供。讀 `README.md` 的表格時
不要預期能在 `skills/` 找到全部四個 Apple 技能。

### `.claude/skills/`、`.agents/skills/`、`.grok/skills/`

其他 agent 工具的技能探索路徑。`內容與 skills/ 不同步`：目前 `.claude/skills/` 只有
`cleaning-vscode-forks` 一個，缺 `apple-calendar` 與 `apple-reminders`。改動技能時
須自行決定要同步哪幾份，`沒有機制`會偵測分岔。

### `.gitignore`

1498 行，逐一列出各 submodule 的建置產物路徑（`mactrans/.build/...` 之類）。
它忽略的是`submodule 工作目錄內`的產物，避免這些檔案干擾分類層的 `git status`。
新增 submodule 且該專案會產生建置產物時，需在此補上對應路徑。

## 開發指南 (Development Guide)

分類層無建置、無測試、無部署。各專案的指令見各自的 `CLAUDE.md` 與 `package.json`。

## 待整理事項 (Housekeeping)

- `.claude/skills/`、`.agents/skills/`、`.grok/skills/` 與 `skills/` 內容不一致。
- submodule `skills` 的 name 與 path（`skills-cli`）不一致。
- `macemailapp/tmp/SKILL.md` 是殘留的 `apple-notes` 複本，應在該 submodule 內刪除。
- `.vscode/` 為空目錄。

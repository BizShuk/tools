# tools/ — 技術脈絡 (Technical Context)

本檔記錄本分類的目錄結構、submodule 機制與慣例。技能清單與安裝方式由
[README.md](README.md) 單一擁有，本檔不重複。

## 目錄結構 (Directory Layout)

```tree
tools/
├── README.md                     # 插件說明與技能清單
├── CLAUDE.md                     # 本檔
├── AGENTS.md -> CLAUDE.md        # 軟連結
├── .gitmodules                   # 20 個 submodule 的 path / url / branch
├── .gitignore                    # 逐 submodule 列出的建置產物忽略清單
├── .claude-plugin/plugin.json    # Claude Code plugin manifest
├── skills/                       # 分類層自有技能 (3 個)
├── .claude/skills/               # 分類層之外另一份技能探索路徑
├── .agents/skills/ .grok/skills/ # 同上, 供其他 agent 工具探索
├── .vscode/                      # 目前為空目錄
└── <20 個 submodule 目錄>        # 各自獨立的 repo, 見 .gitmodules
```

## Submodule 機制 (Submodule Mechanics)

本分類 repo 的 `origin` 是 `BizShuk/tools`。20 個專案全部以 git submodule 掛載，
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
  若要暴露成技能，於 `.claude-plugin/plugin.json` 的 `skills` 陣列登記。
- submodule 內的變更`在該 submodule 內 commit 與 push`；分類層只記錄 gitlink。
- 分類層不對 submodule 做跨 repo 的批次建置；各專案的指令見各自 `package.json`。

## 分類層自身檔案 (Category-Level Files)

### `.claude-plugin/plugin.json`

把本分類發布成一個 Claude Code plugin（`name: tools`）。技能來源有`兩處`：

- `skills/` 目錄下的技能由 plugin loader `自動探索`，不在 manifest 列舉。
- `skills` 陣列列出`由 submodule 提供`的技能，形式為 `bizshuk/<submodule>`：
  `autop`、`macemailapp`、`macnotesapp`、`mdserver`、`pm2`、`proxy`。

`已知落差 (Known gap)：` manifest 的 `bizshuk/proxy` 目前找不到對應技能——
`proxy/` 底下沒有 `skills/` 目錄，也沒有任何 `SKILL.md`；該 submodule 只有
`plugins/proxy-imagegen/`（一個 MCP plugin，非 skill）。其餘五項可在
`<submodule>/skills/` 下找到對應目錄。

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

- `plugin.json` 的 `bizshuk/proxy` 指向不存在的技能。
- `.claude/skills/`、`.agents/skills/`、`.grok/skills/` 與 `skills/` 內容不一致。
- `README.md` 的技能表未涵蓋 `cleaning-vscode-forks`，也未說明 `apple-email` 與
  `apple-notes` 來自 submodule。
- submodule `skills` 的 name 與 path（`skills-cli`）不一致。
- `.vscode/` 為空目錄。

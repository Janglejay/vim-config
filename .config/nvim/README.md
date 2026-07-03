# Neovim 配置

一套完整的 Neovim 配置，完全替代 IntelliJ IDEA，支持 Java、Python、TypeScript/Vue、Rust 等多种语言的开发。

---

## 目录

1. [特性概览](#特性概览)
2. [安装](#安装)
3. [配置结构](#配置结构)
4. [核心功能](#核心功能)
5. [快捷键](#快捷键)
6. [语言支持](#语言支持)
7. [Java 开发专题](#java-开发专题)
8. [故障排除](#故障排除)

---

## 特性概览

| 功能 | 实现方案 | IDEA 对应 |
|------|----------|-----------|
| **代码导航** | fzf-lua + jdtls/LSP | Search Everywhere / Goto |
| **代码补全** | nvim-cmp + LSP | 智能补全 |
| **代码格式化** | conform.nvim | `Cmd+Alt+L` |
| **调试** | nvim-dap + dap-ui | Debug 工具窗口 |
| **测试运行** | neotest + neotest-java | JUnit 运行器 |
| **版本控制** | gitsigns + diffview | Git 工具窗口 |
| **调用链分析** | lspsaga | Call Hierarchy |
| **文件结构** | aerial.nvim | Structure |
| **方法跳转** | treesitter | `Ctrl+Up/Down` |

---

## 安装

### 前提条件

| 依赖 | 版本 | 安装 |
|------|------|------|
| Neovim | 0.10+ | `brew install neovim` |
| Java | 21 | `brew install --cask zulu@21` |
| ripgrep | - | `brew install ripgrep` |
| fd | - | `brew install fd` |
| fzf | - | `brew install fzf` |
| Node.js | 18+ | `brew install node` |
| Git | - | `brew install git` |

### 快速开始

```bash
# 1. 克隆配置
git clone <repo> ~/.config/nvim

# 2. 启动 Neovim（自动下载 lazy.nvim 和插件）
nvim

# 3. 安装 Mason 工具
:MasonUpdate

# 4. 安装 Treesitter 解析器（自动异步安装）
```

---

## 配置结构

```
~/.config/nvim/
├── init.vim                      # 入口：设置 runtimepath
├── lazy-lock.json               # 插件版本锁定
├── lua/
│   ├── init.lua                 # lazy.nvim 初始化
│   └── user/
│       ├── options.lua          # Neovim 基础选项
│       ├── keymaps.lua          # 全局快捷键
│       ├── autocommands.lua     # 自动命令
│       ├── cmp.lua              # 自动补全配置
│       ├── plugins/
│       │   ├── init.lua         # 插件汇总入口
│       │   ├── java.lua         # ★ Java LSP (jdtls)
│       │   ├── lsp.lua          # LSP 服务器 + Mason
│       │   ├── search.lua       # fzf-lua + aerial + 书签
│       │   ├── spring.lua       # Spring HTTP 接口搜索
│       │   ├── dap.lua          # 调试器
│       │   ├── test.lua         # 测试运行器
│       │   ├── editing.lua      # Treesitter + 文本对象
│       │   ├── git.lua          # Git 集成
│       │   └── ui.lua           # UI 组件
│       └── lsp/
│           ├── handlers.lua     # LSP 通用配置
│           └── conform.lua      # 格式化器配置
└── docs/
    └── java-dev-guide.md        # Java 开发详细指南
```

---

## 核心功能

### 1. 代码导航

#### 1.1 定义与引用

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `gd` | 智能跳转 | 定义处→显示引用，引用处→跳转定义 |
| `gD` | 跳到声明 | - |
| `gr` | 查找引用 | 过滤 Maven `.m2` 依赖 |
| `gi` | 跳到实现 | 接口→实现类 |
| `gu` | 跳到父类/接口 | Java 专属 |
| `gR` | 调用链 | 来调者树 (lspsaga GUI) |

#### 1.2 搜索体系

| 快捷键 | 用途 | 实现方式 |
|--------|------|----------|
| `<Leader>f` | 搜类/接口/方法名 | ripgrep 即时扫描 |
| `<Leader>F` | 全文内容搜索 | live grep |
| `<Leader>ha` | Spring HTTP 接口 | 扫描 `@Mapping` 注解 |
| `<Leader>e` | 最近文件 | - |
| `<Leader>s` | 文件结构大纲 | aerial |

#### 1.3 方法级跳转（Treesitter）

| 快捷键 | 功能 | IDEA 对应 |
|--------|------|-----------|
| `J` | 跳到下一个方法 | `Ctrl+Down` |
| `K` | 跳到上一个方法 | `Ctrl+Up` |
| `f` | AceJump 字符跳转 | AceJump |
| `F` | AceJump Treesitter 选择 | - |

**文本对象**（Visual/Operator 模式）：
- `af` / `if`：方法外部/内部
- `ac` / `ic`：类外部/内部
- `aa` / `ia`：参数外部/内部

### 2. 代码补全

使用 `nvim-cmp` 提供上下文感知的自动补全：

| 按键 | 功能 |
|------|------|
| `<C-e>` | 上一个候选 |
| `<C-u>` | 下一个候选 |
| `<CR>` | 确认选择 |
| `<Tab>` | 选择下一个 / 展开片段 |
| `<S-Tab>` | 选择上一个 |

**补全来源**：LSP、Snippets、Buffer、Path

### 3. 代码格式化

**手动触发**：`=`（选中或全文件）

| 文件类型 | 格式化器 |
|----------|----------|
| Java | google-java-format |
| Python | black + isort + ruff |
| Lua | stylua |
| JSON/JSONC | jq (2空格) |
| YAML | yamlfmt |
| JS/TS/Vue/CSS/HTML | prettier |

> 注意：不自动格式化保存，完全手动控制

### 4. 调试（nvim-dap）

| 快捷键 | 功能 | IDEA |
|--------|------|------|
| `bb` | 切换断点 | `F9` |
| `bc` | 条件断点 | `Ctrl+Shift+F8` |
| `br` | 继续运行 | `F9` |
| `bi` | 单步进入 | `F7` |
| `bn` | 单步跳过 | `F8` |
| `bp` | 单步返回 | `Shift+F8` |
| `bf` | 运行到光标 | `Alt+F9` |
| `be` | 表达式求值 | `Alt+F8` |
| `bv` | 查看断点面板 | - |
| `sd` | 切换调试 UI | - |

**远程调试**：`br` → 选择 "Remote Debug (Attach)" → 输入 `host:port`

### 5. 测试运行（neotest）

| 快捷键 | 功能 |
|--------|------|
| `zr` | 运行当前文件测试 |
| `zR` | 运行整个项目测试 |
| `zd` | 调试最近测试方法 |
| `zD` | 调试整个项目测试 |
| `sr` | 切换测试结果面板 |

### 6. Git 集成

**gitsigns（行内）**：
| 快捷键 | 功能 |
|--------|------|
| `<C-d>` | 下一个 hunk |
| `<C-f>` | 上一个 hunk |
| `gp` | 预览 hunk |
| `<C-u>` | 重置 hunk |

**diffview（面板）**：
| 快捷键 | 功能 |
|--------|------|
| `<Leader>gd` | 查看所有改动 |
| `<Leader>gh` | 当前文件历史 |
| `<Leader>gH` | 全项目历史 |
| `<Leader>gc` | 关闭 diffview |
| `<Leader>gf` | 在 Fork 中打开 |

### 7. LSP 功能

| 快捷键 | 功能 | IDEA |
|--------|------|------|
| `<Leader>R` | 重命名 | `Shift+F6` |
| `ga` | Code Action | `Alt+Enter` |
| `<c-p>` | Hover 文档 | `F1` |
| `qt` | 类型定义 | - |
| `qd` | Quick JavaDoc | - |
| `<Leader>oi` | 整理导入 (Java) | `Ctrl+Alt+O` |
| `<Leader>T` | 重构菜单 (Java) | `Ctrl+Alt+Shift+T` |
| `<Leader>ih` | 切换 Inlay Hints | 参数名提示 |
| `se` | 显示诊断 | - |
| `<F2>` | 下一个错误 | `F2` |

### 8. 窗口与工具

| 快捷键 | 功能 |
|--------|------|
| `gh/gj/gk/gl` | 窗口导航 |
| `sV` / `sv` | 水平/垂直分割 |
| `sl` / `sh` | 下一个/上一个窗口 |
| `sw` | 在新窗口打开定义 |
| `sq` | 关闭窗口 |
| `<Leader>w` | 隐藏/恢复所有工具窗口 |
| `<Leader><Arrow>` | 调整窗口大小 |
| `gw` | 切换文件树 |
| `<Leader>P` | 定位当前文件 |
| `st` | 打开终端 |

### 9. 书签

| 快捷键 | 功能 | IDEA |
|--------|------|------|
| `mm` | 打标/取消书签 | `F11` |
| `ma` | 查看所有书签 | `Shift+F11` |
| `gm` | 下一个书签 | `F4` |
| `gM` | 上一个书签 | `Shift+F4` |

### 10. 折叠

| 快捷键 | 功能 |
|--------|------|
| `zz` | 折叠/展开当前块 |
| `zZ` | 折叠/展开所有 |
| `zc` | 居中当前行 |
| `zO` | 全部展开 |

---

## 快捷键

> `<Leader>` = `,`（逗号键）

### 快速参考卡

```
【导航】
  gd   智能跳转定义/引用
  gr   查找所有引用
  gi   跳到实现
  gR   调用链分析
  J/K  下一个/上一个方法
  f/F  AceJump

【搜索】
  <Leader>f   搜类/方法名
  <Leader>F   全文搜索
  <Leader>ha  Spring 接口
  <Leader>e   最近文件
  <Leader>s   文件结构

【编辑】
  =    格式化
  ga   快速修复
  <Leader>R   重命名
  <Leader>oi  整理导入

【调试】
  bb   切换断点
  br   继续运行
  bi   单步进入
  bn   单步跳过
  sd   调试面板

【测试】
  zr   运行当前文件
  zR   运行全部
  zd   调试测试
  sr   测试结果面板

【Git】
  <Leader>gd  Git diff
  gp   预览 hunk
  <C-d>/<C-f>  hunk 跳转

【窗口】
  gh/j/k/l  窗口导航
  <Leader>w  隐藏/恢复工具
  gw   文件树
```

---

## 语言支持

### Java

- **LSP**: jdtls (Eclipse JDT Language Server)
- **调试**: nvim-dap (内置 Java 适配器)
- **测试**: neotest-java (JUnit 4/5)
- **格式化**: google-java-format
- **特色功能**: Lombok 支持、Spring Boot LS、调用链分析

[详细 Java 开发指南 →](./docs/java-dev-guide.md)

### Python

- **LSP**: pyright
- **格式化**: black + isort + ruff
- **调试**: nvim-dap (需手动配置 debugpy)

### TypeScript / JavaScript / Vue

- **LSP**: ts_ls (TypeScript), vue_ls (Vue 3), eslint
- **格式化**: prettier
- **特色**: Vue 单文件组件完整支持、ESLint 集成

### 其他语言

| 语言 | LSP | 格式化 |
|------|-----|--------|
| Lua | builtin | stylua |
| Rust | rust_analyzer | builtin |
| Go | gopls | builtin |
| JSON | builtin | jq |
| YAML | builtin | yamlfmt |
| CSS/SCSS | cssls | prettier |
| HTML | html | prettier |

---

## Java 开发专题

### 索引管理

jdtls 状态显示在状态栏：
- `✓ jdtls`（绿色）= 索引完成
- `󰔟 jdtls`（橙色）= 正在索引
- `✗ jdtls`（红色）= 未连接

| 快捷键 | 功能 |
|--------|------|
| `<Leader>jr` | 软刷新（pom.xml 变更后同步）|
| `<Leader>jR` | 全量重建（删除 workspace 重启，约 1-3 分钟）|

### 大型项目优化

对于美团内部大型多模块 Maven 项目：

1. **内存分配**: 已配置 `-Xmx6g`，OOM 时改 `java.lua` 的 `--jvm-arg=-Xmx8g`
2. **超时设置**: LSP 请求超时已设置为 60 秒
3. **排除目录**: 自动排除 `target/`, `node_modules/`, `.git/`, `.gradle/`, `.idea/`

### Spring Boot 支持

可选安装 Spring Boot Language Server：

```bash
bash ~/.config/nvim/scripts/install-spring-boot-ls.sh
```

提供：
- Bean 定义导航
- `@RequestMapping` 补全
- `application.yml/properties` 智能提示

---

## 故障排除

### 通用检查清单

```vim
:checkhealth          " 环境健康检查
:LspInfo             " LSP 客户端状态
:LspLog              " LSP 日志
:Mason               " 管理 LSP 工具
:Lazy                " 插件管理
```

### 常见问题

**Q: jdtls 显示 `✗` 未连接**
- 确认当前文件是 `.java`
- 确认项目根有 `pom.xml` 或 `build.gradle`
- 检查 Java 21: `/usr/libexec/java_home -v 21`
- 检查 jdtls 安装: `:Mason`

**Q: `gd` 跳转没反应**
- 等待状态栏显示 `✓ jdtls`
- 若显示 `󰔟`，索引尚未完成

**Q: 格式化不生效**
- 确认格式化器已安装: `:Mason`
- 手动触发: `=`
- 检查 conform 配置: `:ConformInfo`

**Q: 补全不工作**
- 确认 LSP 已连接: `:LspInfo`
- 检查 cmp 状态: `:CmpStatus`

### 更新维护

```vim
:Lazy update          " 更新插件
:MasonUpdate          " 更新 Mason 工具
:TSUpdate             " 更新 Treesitter 解析器
```

---

## 自定义

### 添加新 LSP 服务器

编辑 `lua/user/plugins/lsp.lua`：

```lua
vim.lsp.config("myserver", {
  cmd = { mason_bin .. "/myserver", "--stdio" },
  filetypes = { "myfiletype" },
  root_markers = { ".git", "config.json" },
  on_attach = handlers.on_attach,
  capabilities = handlers.capabilities,
})
vim.lsp.enable("myserver")
```

### 添加格式化器

编辑 `lua/user/lsp/conform.lua`：

```lua
formatters_by_ft = {
  myfiletype = { "myformatter" },
}
```

### 添加快捷键

编辑 `lua/user/keymaps.lua`：

```lua
vim.keymap.set("n", "<Leader>x", ":MyCommand<CR>", { noremap = true, silent = true })
```

---

## 参考

- [Java 开发详细指南](./docs/java-dev-guide.md)
- [lazy.nvim 文档](https://github.com/folke/lazy.nvim)
- [nvim-jdtls 文档](https://github.com/mfussenegger/nvim-jdtls)
- [fzf-lua 文档](https://github.com/ibhagwan/fzf-lua)
